// serverConnectionType := ConnectionType.Tcp
// serverPort := 4273
Global / semanticdbEnabled := true

// manually set the version because the default may not be available for the latest version of scala in maven
// default in sbt 1.9.2 is 4.7.8
// https://github.com/sbt/sbt/blob/fe4c5159a127dd6261c1c2f53942458261b7487b/main/src/main/scala/sbt/plugins/SemanticdbPlugin.scala#L30

// now sbt-metals defines the default version, as of 1.0 it is 4.8.3
// https://github.com/scalameta/metals/blob/3776cef9f8402d7ebc2edb7a91c3da48629e1ad7/project/V.scala#L41
// https://github.com/scalameta/metals/blob/3776cef9f8402d7ebc2edb7a91c3da48629e1ad7/project/V.scala#L43C20-L43C29
// https://github.com/scalameta/metals/blob/3776cef9f8402d7ebc2edb7a91c3da48629e1ad7/build.sbt#L507
// https://github.com/scalameta/metals/blob/3776cef9f8402d7ebc2edb7a91c3da48629e1ad7/sbt-metals/src/main/scala/scala/meta/metals/MetalsPlugin.scala#L31

// It is recent enough as of this writing, but this might need manual overriding in the future again, so leaving the comment for posteriority:
// Global / semanticdbVersion := "4.7.8"
