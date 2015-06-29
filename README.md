A very literal port of the Obj-C version of the WhirlyGlobe-Maply
tutorials to Swift (Xcode6.3.2 and Swift 1.2).

This version shows an issue with the CartoDBLayer tutorial where Swift
doesnt like MaplyPagingDelegate's required int properties; this is
referenced in https://github.com/mousebird/WhirlyGlobe/issues/326

NB: To install/test you will need to drag the unzipped 
WhirlyGlobe_Maply_Distribution_2_3 into the top-level here. 
(it doesn't get caught up in the git repo since it has it's own .git files)
