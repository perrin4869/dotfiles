// the length limits are formatting rather than the convention: bodies here wrap at 120, and dependabot's notes not at all
export default {
	extends: ['@commitlint/config-conventional'],
	rules: {
		'header-max-length': [0],
		'body-max-line-length': [0],
		'footer-max-line-length': [0],
	},
};
