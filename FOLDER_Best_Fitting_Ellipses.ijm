macro "Batch Best Fitting Ellipses" {
    //prompt user to select folder
    dir = getDirectory("Choose a folder containing .tif images");

    //get all .tif files in the folder
    list = getFileList(dir);
    for (i = 0; i < list.length; i++) {
        filename = list[i];
        if (endsWith(filename, ".tif")) {
            fullPath = dir + filename;
            baseName = replace(filename, ".tif", "");

            //close all images and clear managers
            close("*");
            roiManager("reset");
            run("Clear Results");

            //open the image
            open(fullPath);
            originalImage = getTitle();

            //run StarDist 2D
            run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" 
                + originalImage + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', "
                + "'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', "
                + "'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', "
                + "'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

            selectImage(originalImage);

            //measure ROIs (in calibrated units)
            run("Set Measurements...", "area centroid perimeter fit shape feret's mean redirect=None decimal=2");
            roiManager("Measure");

            //store measurements
            getVoxelSize(rescale, height, depth, unit); //get image size for rescale
            roiManager("reset"); //clear ROI manager before adding ellipse overlays

			//draw best fitting ellipse and its axes
            n = nResults;
            for (j = 0; j < n; j++) {
                xc = getResult("X", j) / rescale;
                yc = getResult("Y", j) / rescale;
                major = getResult("Major", j) / rescale;
                minor = getResult("Minor", j) / rescale;
                angle = getResult("Angle", j);

                makeOval(xc - (major/2), yc - (minor/2), major, minor);
                run("Rotate...", "angle=" + (180 - angle));
                roiManager("Add"); //add this ellipse to the ROI Manager
                run("Overlay Options...", "stroke=green width=0 fill=none");
                run("Add Selection...");

				//draw major axis (blue)
                a = angle * PI / 180; //convert angle to radians
                d = major;
                run("Overlay Options...", "stroke=blue width=0 fill=none");
                makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
                run("Add Selection...");

				//draw minor axis (red)
                a = a + PI/2; //rotate 90° for the minor axis
                d = minor;
                run("Overlay Options...", "stroke=red width=0 fill=none");
                makeLine(xc + (d/2)*cos(a), yc - (d/2)*sin(a), xc - (d/2)*cos(a), yc + (d/2)*sin(a));
                run("Add Selection...");
            }
            run("Select None");

            run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixel"); //convert scale to pixels

   		 	//clear previous results and measure all ellipse ROIs (now in pixel units)
            run("Clear Results");
            for (k = 0; k < roiManager("count"); k++) {
                roiManager("Select", k);
                roiManager("Measure");
            }

            //save the results
            saveAs("Results", dir + baseName + ".csv");

            roiManager("reset");
            close();
        }
    }
    showMessage("Batch Processing", "Finished processing all .tif files in:\n" + dir);
}
