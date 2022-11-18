// serverConnectionType := ConnectionType.Tcp
// serverPort := 4273
Global / semanticdbEnabled := true
// manually set the version because the default may not be available for the latest version of scala in maven
// https://github.com/sbt/sbt/blob/2dad7ea76385261aa542b5e7410d50d19e1a496a/main/src/main/scala/sbt/plugins/SemanticdbPlugin.scala#L29
// default in sbt 1.8 is 4.5.1
// update to latest
Global / semanticdbVersion := "4.6.0"
