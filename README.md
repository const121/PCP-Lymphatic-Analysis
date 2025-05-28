# PCP-Lymphatic-Analysis

# Nuclei Ellipse Fitting and Vessel Alignment Toolkit

This repository contains ImageJ and MATLAB scripts for analyzing fluorescent nuclei images. It includes tools to fit ellipses to nuclei using StarDist and ImageJ macros, and to post-process and visualize nuclei alignment with respect to a user-defined vessel axis in MATLAB.

## Contents

### 1. `ONE_Best_Fitting_Elipses.ijm`

**Description:**  
An ImageJ/FIJI macro to process a single image by fitting ellipses to nuclei using StarDist 2D, and drawing their major and minor axes on the original image. The final measurements are converted to pixel units for downstream analysis.

**Steps Performed:**
- Open `.tif` image in ImageJ/FIJI.
- Runs StarDist 2D on the currently selected image.
- Draws best-fitting ellipses and overlays major (blue) and minor (red) axes.
- Converts image scale to pixels and re-measures all ROIs.
- Outputs measurements in ImageJ’s Results table.
- Save results as `.csv`.

**Usage:**
1. Open a .tif image in ImageJ.
2. Run the macro from the script editor or Plugins > Macros > Run.
3. Results will be shown in the Results table.

---

### 2. `FOLDER_Best_Fitting_Elipses.ijm`

**Description:**  
A batch version of the above macro (ONE_Best_Fitting_Elipses.ijm) that processes all `.tif` images in a selected folder.

**Steps Performed:**
- Prompts the user to select a folder containing `.tif` images.
- For each image:
  - Runs StarDist 2D and fits ellipses.
  - Draws ellipses and axes as overlays.
  - Converts measurements to pixel units.
  - Saves a `.csv` file with the results.

**Usage:**
1. Open ImageJ.
2. Run the macro and select your image folder.
3. A `.csv` file will be created for each image in the same directory.

---

### 3. `VesselCells_HandCorrection.m`

**Description:**  
A MATLAB script for analyzing nuclei alignment relative to a manually defined vessel axis.

**Steps Performed:**
- Loads ellipse data from a `.csv` file and a corresponding `.tif` image.
- Filters nuclei by area and fluorescence intensity.
- Allows manual selection of the vessel midline.
- Allows manual deletion/hand correction of the valve cells.
- Computes angle differences between each nucleus and the vessel direction.
- Visualizes nuclei with color overlays based on alignment metrics.

**User Parameters:**
- `fluorescent_intensity`: Percentile threshold for mean fluorescence.
- `csv_file`: Path to the `.csv` file from ImageJ.
- `tif_file`: Path to the associated `.tif` image.

**Usage:**
1. Update the file paths in the parameter section.
2. Adjust the fluorescent intensity in the paremeter section. 
3. Run the script.
4. Select the vessel midline in the image (two clicks).
5. Select the cells to delete, then press `ENTER`(PC) or `RETURN`(Mac) when done. 
6. View the resulting overlay figures and alignment metrics. Save the figures. 
7. Save results as `.csv` for future analysis. 

---

## 4. Example Binary Image

**Description:**  
An example binary image of a vessel to test and understand the workflow.

**Steps Performed:**
- Use ONE_Best_Fitting_Elipses.ijm in ImageJ/FIJI to segment nuclei with StarDist 2D and fit ellipses.
- Export results data table as a `.csv` file.
- Load the `.csv` and corresponding `.tif` image into VesselCells_HandCorrection.m.
- Export figures and hand correction results. 

**User Parameters:**
- `fluorescent_intensity`: Percentile threshold for mean fluorescence.
- `csv_file`: Path to the `.csv` file from ImageJ.
- `tif_file`: Path to the associated `.tif` image.

**Usage:**
1. Run ONE_Best_Fitting_Elipses.ijm.
2. Save results as `.csv`.
3. Run VesselCells_HandCorrection.m.
3. Save figures and results. 

---

## Dependencies

- **ImageJ/Fiji** with the [StarDist](https://github.com/stardist/stardist) plugin installed. Enable CSBDeep and StarDist in updates menu. 
- **MATLAB** R2020 or newer.
- Input images should be `.tif` format.
- Ellipse data must be exported via the ImageJ/FIJI macros in this repository as `.csv`.

---

## Acknowledgments

- [StarDist 2D](https://github.com/stardist/stardist) by Uwe Schmidt and Martin Weigert.
- Developed as part of image analysis workflows for vessel-aligned nuclear orientation studies.

---

## How to cite



