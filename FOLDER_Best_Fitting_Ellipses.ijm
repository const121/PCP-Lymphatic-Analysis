macro "Batch Best Fitting Ellipses" {
    // Prompt user to select folder
    dir = getDirectory("Choose a folder containing .tif images");

    // Get all .tif files in the folder
    list = getFileList(dir);
    for (i = 0; i < list.length; i++) {
        filename = list[i];
        if (endsWith(filename, ".tif")) {
            fullPath = dir + filename;
            baseName = replace(filename, ".tif", "");

            // Close all images and clear managers
            close("*");
            roiManager("reset");
            run("Clear Results");

            // Open the image
            open(fullPath);
            originalImage = getTitle();

            // Run StarDist 2D
            run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" 
                + originalImage + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', "
                + "'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', "
                + "'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', "
                + "'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

            selectImage(originalImage);

            // Measure ROIs (in calibrated units)
            run("Set Measurements...", "area centroid perimeter fit shape feret's mean redirect=None decimal=2");
            roiManager("Measure");

            // Store measurements
            getVoxelSize(rescale, height, depth, unit);
            roiManager("reset");

            n = nResults;
            for (j = 0; j < n; j++) {
                xc = getResult("X", j) / rescale;
                yc = getResult("Y", j) / rescale;
                major = getResult("Major", j) / rescale;
                minor = getResult("Minor", j) / rescale;
                angle = getResult("Angle", j);

                makeOval(xc - (major/2), yc - (minor/2), major, minor);
                run("Rotate...", "angle=" + (180 - angle));
                roiManager("Add");
                run("Overlay Options...", "stroke=green width=0 fill=none");
                run("Add Selection...");

                a = angle * PI / 180;
                d = major;
                run("Overlay Options...", "stroke=blue width=0 fill=none");
                makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
                run("Add Selection...");

                a = a + PI/2;
                d = minor;
                run("Overlay Options...", "stroke=red width=0 fill=none");
                makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
                run("Add Selection...");
            }
            run("Select None");

            // Convert scale to pixels
            run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixel");

            // Clear previous results
            run("Clear Results");

            // Measure all ROIs in pixel units
            for (k = 0; k < roiManager("count"); k++) {
                roiManager("Select", k);
                roiManager("Measure");
            }

            // Save the results
            saveAs("Results", dir + baseName + ".csv");

            // Clean up
            roiManager("reset");
            close();
        }
    }

    // Done
    showMessage("Batch Processing", "Finished processing all .tif files in:\n" + dir);
}
