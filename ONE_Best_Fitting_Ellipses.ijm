macro "Draw Best Fitting Ellipses" {
    roiManager("reset"); //reset ROI manager and record image title
    originalImage = getTitle();

    // Run StarDist 2D
    run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" 
        + originalImage + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', "
        + "'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', "
        + "'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', "
        + "'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

    selectImage(originalImage);

    run("Set Measurements...", "area centroid perimeter fit shape feret's mean redirect=None decimal=2"); //set measurements
    roiManager("Measure");

    roiManager("reset"); //clear ROI manager before adding ellipse overlays

    getVoxelSize(rescale, height, depth, unit); //get image size for rescale

    //draw best fitting ellipse and its axes
    for(i = 0; i < nResults; i++) {
        //convert to pixel units
        xc = getResult("X", i) / rescale;
        yc = getResult("Y", i) / rescale;
        major = getResult("Major", i) / rescale;
        minor = getResult("Minor", i) / rescale;
        angle = getResult("Angle", i);
        
        makeOval(xc - (major/2), yc - (minor/2), major, minor);
        run("Rotate...", "angle=" + (180 - angle)); //adjust rotation
        roiManager("Add");  //add this ellipse to the ROI Manager
        run("Overlay Options...", "stroke=green width=0 fill=none");
        run("Add Selection...");

        //draw major axis (blue)
        a = angle * PI / 180; //convert angle to radians
        d = major;
        run("Overlay Options...", "stroke=blue width=0 fill=none");
        makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
        run("Add Selection...");

        //draw minor axis (red)
        a = a + PI/2;  //rotate 90° for the minor axis
        d = minor;
        run("Overlay Options...", "stroke=red width=0 fill=none");
        makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
        run("Add Selection...");
    }
    run("Select None");

    run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixel"); //convert to pixels

    //clear previous results and measure all ellipse ROIs (now in pixel units)
    run("Clear Results");
    for (i = 0; i < roiManager("count"); i++) {
        roiManager("Select", i);
        roiManager("Measure");
    }
}
