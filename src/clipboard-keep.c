/* Hold the CLIPBOARD selection so a copy outlives the program that made it, keeping every target the
 * copy offered and not only the text: a file list keeps x-special/gnome-copied-files and text/uri-list
 * (so a cut stays a cut), an image keeps its image/png. One slot, in memory, nothing on disk. */
#define _POSIX_C_SOURCE 200809L

#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <time.h>

#define PROP "CLIPBOARD_KEEP"
#define TIMEOUT_MS 2000
#define INCR_AT 200000 /* well under the 256KiB property size that X servers commonly cap */

struct item {
	Atom target, type;
	unsigned char *data;
	unsigned long len;
};

static Display *dpy;
static Window win;
static Atom a_clipboard, a_targets, a_timestamp, a_incr, a_prop;
static struct item *items;
static int nitems;
static struct {
	Window requestor;
	Atom property, type;
	const unsigned char *data;
	unsigned long len, off;
	int active;
} out;

/* Wait for an event; ms < 0 blocks. Returns 0 on timeout. */
static int next_event(XEvent *ev, int ms)
{
	int fd = ConnectionNumber(dpy);

	XFlush(dpy); /* whatever we queued is what the event is a reply to */
	while (!XPending(dpy)) {
		fd_set fds;
		struct timeval tv = { ms < 0 ? 0 : ms / 1000, ms < 0 ? 0 : (ms % 1000) * 1000 };

		FD_ZERO(&fds);
		FD_SET(fd, &fds);
		if (select(fd + 1, &fds, NULL, NULL, ms < 0 ? NULL : &tv) <= 0)
			return 0;
	}
	XNextEvent(dpy, ev);
	return 1;
}

static void cache_clear(void)
{
	int i;

	for (i = 0; i < nitems; i++)
		free(items[i].data);
	free(items);
	items = NULL;
	nitems = 0;
}

static struct item *cache_find(Atom target)
{
	int i;

	for (i = 0; i < nitems; i++)
		if (items[i].target == target)
			return &items[i];
	return NULL;
}

static void cache_add(Atom target, Atom type, unsigned char *data, unsigned long len)
{
	struct item *item = cache_find(target);

	if (item) {
		free(item->data);
	} else {
		items = realloc(items, sizeof(*items) * (nitems + 1));
		item = &items[nitems++];
		item->target = target;
	}
	item->type = type;
	item->data = data;
	item->len = len;
}

/* Read the whole of a property owned by our window into a malloc'd buffer. Xlib hands format 32
 * items back as longs, so the byte count follows sizeof(long) there and the item size elsewhere. */
static int read_prop(Atom property, Atom *type, unsigned char **buf, unsigned long *len)
{
	unsigned char *p = NULL;
	unsigned long nitems = 0, after = 0, bytes;
	int format = 8;
	Atom t;

	*type = None;
	*buf = NULL;
	*len = 0;
	if (XGetWindowProperty(dpy, win, property, 0, (long)((~0UL) / 4), False, AnyPropertyType,
	                       &t, &format, &nitems, &after, &p) != Success || t == None) {
		XFree(p);
		return 0;
	}
	bytes = nitems * (format == 32 ? sizeof(long) : (unsigned long)format / 8);
	*buf = malloc(bytes ? bytes : 1);
	if (bytes)
		memcpy(*buf, p, bytes);
	XFree(p);
	*type = t;
	*len = bytes;
	return 1;
}

/* Ask the owner for one target; understands INCR, which large payloads always take. */
static int fetch(Atom target, Atom *type_out, unsigned char **data_out, unsigned long *len_out)
{
	XEvent ev;
	Atom type = None;
	unsigned char *data = NULL;
	unsigned long len = 0;
	int notified = 0;

	XDeleteProperty(dpy, win, a_prop);
	XConvertSelection(dpy, a_clipboard, target, a_prop, win, CurrentTime);
	XFlush(dpy);
	while (next_event(&ev, TIMEOUT_MS)) {
		if (ev.type == SelectionNotify) {
			if (ev.xselection.property == None)
				return 0;
			notified = 1;
			break;
		}
	}
	if (!notified || !read_prop(a_prop, &type, &data, &len))
		return 0;
	if (type != a_incr) {
		*type_out = type;
		*data_out = data;
		*len_out = len;
		return 1;
	}
	/* INCR: each chunk arrives as a new value of the property, and deleting it asks for the next. */
	XFree(data);
	data = NULL;
	len = 0;
	XDeleteProperty(dpy, win, a_prop);
	for (;;) {
		unsigned char *chunk = NULL;
		unsigned long n = 0;

		/* Our own delete of the previous chunk arrives here too; only new values are data. */
		if (!next_event(&ev, TIMEOUT_MS))
			break;
		if (ev.type != PropertyNotify || ev.xproperty.atom != a_prop ||
		    ev.xproperty.state != PropertyNewValue)
			continue;
		if (!read_prop(a_prop, &type, &chunk, &n) || n == 0) {
			free(chunk);
			break;
		}
		data = realloc(data, len + n);
		memcpy(data + len, chunk, n);
		len += n;
		free(chunk);
		XDeleteProperty(dpy, win, a_prop);
	}
	*type_out = target;
	*data_out = data;
	*len_out = len;
	return 1;
}

/* Take a copy of every pasteable target the current owner offers. */
static void grab(void)
{
	Window owner = XGetSelectionOwner(dpy, a_clipboard);
	Atom type, *targets = NULL;
	unsigned long len = 0, i, n;
	unsigned char *raw = NULL;

	cache_clear();
	if (owner == None || owner == win)
		return;
	if (!fetch(a_targets, &type, &raw, &len) || type != XA_ATOM)
		goto out;
	targets = (Atom *)raw;
	n = len / sizeof(Atom);
	for (i = 0; i < n; i++) {
		Atom target = targets[i], t;
		unsigned char *bytes = NULL;
		unsigned long size = 0;

		if (target == a_targets || target == a_timestamp || target == a_incr)
			continue;
		if (fetch(target, &t, &bytes, &size))
			cache_add(target, t, bytes, size);
	}
out:
	free(raw);
}

static void write_chunk(void)
{
	unsigned long n = out.len - out.off;

	if (n > INCR_AT)
		n = INCR_AT;
	/* ICCCM ends an INCR transfer with a zero-length property, sent on the next delete. */
	XChangeProperty(dpy, out.requestor, out.property, out.type, 8, PropModeReplace,
	                n ? out.data + out.off : NULL, (int)n);
	XFlush(dpy);
	if (n == 0)
		out.active = 0;
	else
		out.off += n;
}

static void handle_request(XSelectionRequestEvent *r)
{
	XSelectionEvent reply;
	struct item *item;
	Atom property = r->property == None ? r->target : r->property;

	memset(&reply, 0, sizeof(reply));
	reply.type = SelectionNotify;
	reply.requestor = r->requestor;
	reply.selection = r->selection;
	reply.target = r->target;
	reply.time = r->time;
	reply.property = None;

	if (r->target == a_targets) {
		Atom list[nitems + 2];
		int i;

		list[0] = a_targets;
		list[1] = a_timestamp;
		for (i = 0; i < nitems; i++)
			list[i + 2] = items[i].target;
		XChangeProperty(dpy, r->requestor, property, XA_ATOM, 32, PropModeReplace,
		                (unsigned char *)list, nitems + 2);
		reply.property = property;
	} else if (r->target == a_timestamp) {
		long now = r->time ? (long)r->time : (long)CurrentTime;

		XChangeProperty(dpy, r->requestor, property, XA_INTEGER, 32, PropModeReplace,
		                (unsigned char *)&now, 1);
		reply.property = property;
	} else if ((item = cache_find(r->target)) != NULL) {
		if (item->len > INCR_AT) {
			long hint = (long)item->len;

			/* The requestor deletes the property after each chunk, which we watch for. */
			XSelectInput(dpy, r->requestor, PropertyChangeMask);
			XChangeProperty(dpy, r->requestor, property, a_incr, 32, PropModeReplace,
			                (unsigned char *)&hint, 1);
			out.requestor = r->requestor;
			out.property = property;
			out.type = item->type;
			out.data = item->data;
			out.len = item->len;
			out.off = 0;
			out.active = 1;
		} else {
			XChangeProperty(dpy, r->requestor, property, item->type, 8, PropModeReplace,
			                item->data, (int)item->len);
		}
		reply.property = property;
	}
	XSendEvent(dpy, r->requestor, False, NoEventMask, (XEvent *)&reply);
	XFlush(dpy);
}

/* Serve the slot until another client takes the selection. */
static void serve(void)
{
	XEvent ev;

	XSetSelectionOwner(dpy, a_clipboard, win, CurrentTime);
	XFlush(dpy);
	if (XGetSelectionOwner(dpy, a_clipboard) != win) {
		struct timespec pause = { 0, 200000000 };

		nanosleep(&pause, NULL); /* another keeper has it: retry instead of spinning on the claim */
		return;
	}
	for (;;) {
		if (!next_event(&ev, -1))
			continue;
		switch (ev.type) {
		case SelectionClear:
			return;
		case SelectionRequest:
			handle_request(&ev.xselectionrequest);
			break;
		case PropertyNotify:
			if (out.active && ev.xproperty.window == out.requestor &&
			    ev.xproperty.atom == out.property &&
			    ev.xproperty.state == PropertyDelete)
				write_chunk();
			break;
		}
	}
}

static int on_error(Display *d, XErrorEvent *e)
{
	char text[128];

	(void)d;
	XGetErrorText(dpy, e->error_code, text, sizeof(text));
	fprintf(stderr, "clipboard-keep: %s (request %d.%d)\n", text, e->request_code, e->minor_code);
	return 0;
}

int main(void)
{
	dpy = XOpenDisplay(NULL);
	if (!dpy) {
		fprintf(stderr, "clipboard-keep: cannot open display\n");
		return 1;
	}
	(void)on_error;
	XSetErrorHandler(on_error);
	win = XCreateSimpleWindow(dpy, DefaultRootWindow(dpy), -10, -10, 1, 1, 0, 0, 0);
	XSelectInput(dpy, win, PropertyChangeMask);
	a_clipboard = XInternAtom(dpy, "CLIPBOARD", False);
	a_targets = XInternAtom(dpy, "TARGETS", False);
	a_timestamp = XInternAtom(dpy, "TIMESTAMP", False);
	a_incr = XInternAtom(dpy, "INCR", False);
	a_prop = XInternAtom(dpy, PROP, False);

	grab();
	for (;;) {
		serve();
		grab();
	}
}
