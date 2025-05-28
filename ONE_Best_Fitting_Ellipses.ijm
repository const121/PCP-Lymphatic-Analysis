macro "Draw Best Fitting Ellipses" {
    // Reset ROI Manager and record the original image title
    roiManager("reset");
    originalImage = getTitle();

    // Run StarDist 2D on the original image.
    // 'outputType' is set to "ROI Manager" to avoid generating a label image.
    run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" 
        + originalImage + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', "
        + "'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', "
        + "'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', "
        + "'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

    // Re-select the original image (ensuring overlays and measurements go there)
    selectImage(originalImage);

    // Set measurements (these initial measurements of the StarDist ROIs will be in the calibrated units)
    run("Set Measurements...", "area centroid perimeter fit shape feret's mean redirect=None decimal=2");
    roiManager("Measure");

    // Clear the ROI Manager before adding our ellipse overlays
    roiManager("reset");

    // Retrieve the voxel (pixel) size from the image calibration.
    // 'rescale' is the pixel width in calibrated units (e.g., µm). Dividing by it converts to pixels.
    getVoxelSize(rescale, height, depth, unit);

    // Loop over each StarDist result and draw the ellipse and its axes
    for(i = 0; i < nResults; i++) {
        // Convert the measured (calibrated) values to pixel units
        xc = getResult("X", i) / rescale;
        yc = getResult("Y", i) / rescale;
        major = getResult("Major", i) / rescale;
        minor = getResult("Minor", i) / rescale;
        angle = getResult("Angle", i);
        
        // Draw the ellipse ROI (centered at (xc, yc)) and rotate it accordingly.
        makeOval(xc - (major/2), yc - (minor/2), major, minor);
        run("Rotate...", "angle=" + (180 - angle)); // adjust rotation
        roiManager("Add");  // add this ellipse to the ROI Manager (optional)
        run("Overlay Options...", "stroke=green width=0 fill=none");
        run("Add Selection...");

        // Draw the major axis (blue)
        a = angle * PI / 180; // convert angle to radians
        d = major;
        run("Overlay Options...", "stroke=blue width=0 fill=none");
        makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
        run("Add Selection...");

        // Draw the minor axis (red)
        a = a + PI/2;  // rotate 90° for the minor axis
        d = minor;
        run("Overlay Options...", "stroke=red width=0 fill=none");
        makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
        run("Add Selection...");
    }
    run("Select None");

    // ---------------------------------------------------------------------
    // To ensure the final ROI measurements are in pixel units, we reset the image scale.
    // This overrides the calibrated scale so that measurements (e.g., centroid X and Y)
    // are reported in pixels.
    run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixel");

    // Clear previous results and measure all ellipse ROIs (now in pixel units)
    run("Clear Results");
    for (i = 0; i < roiManager("count"); i++) {
        roiManager("Select", i);
        roiManager("Measure");
    }
}
