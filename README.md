# Strava Activity Mapper

I created this app as an easy way to overlap running data over a period of time. This is my first time dipping my toes in both Shiny and GPS mapping, so it was a good learning experience. The app is tailored for running and can accomodate GPX, fit, and tcx files. I would like to build this app out further to do further analytics on the runs that are imported, but this is a good first step.

## Running the App

### Anaconda Environment

I provide a yml file for easy generation of the Anaconda environment used to create this app as `ActivitMapper.yml`. You can use this in conjuction with `conda env create -f environment.yml` as per [Conda instructions](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#creating-an-environment-from-an-environment-yml-file).

### R and Python Prerequisites

Tested on R 3.6.1
* shiny - 1.5
* stringr - 1.4
* XML - 3.99-0.3
* reticulate - 1.18
* R.utils - 2.10.1
* leaflet - 2.0.4.1
* dplyr 1.0.2

Tested on Python 3.8.2
* fitparse
* pytz

Both of the python packages can be installed using R, see lines 10 and 11 within R.

### Running the App

* Within rstudio, open app.R and click `Run App` from the pulled directory
* From R, call `shiny::runApp("ActivityMapper")`, pointing at the pulled directory
* From https://cambaker.shinyapps.io/activitymapper/, but uptime is not guaranteed and upload is slow 

### Your First Run

Before you can fully use the app, you will need to request your data from Strava. There are instructions on how to do this in the "Bulk Data" section of [Strava's support site](https://support.strava.com/hc/en-us/articles/216918437-Exporting-your-Data-and-Bulk-Export). You will recieve a zip file that you will upload to the app directly. **The app deletes your data after the map is generated**.

## TODO

The most glaring feature that's missing is a way to download your map. You'll have to use screenshots for the time being.

## Acknowledgements

[GPSskyrunners](https://github.com/ssayols/GPSskyrunners) served as an inspiration for the first interation. This [guide](http://rcrastinate.blogspot.com/2014/09/stay-on-track-plotting-gps-tracks-with-r.html) served as a tutorial for parsing GPX files and this [guide](https://maxcandocia.com/article/2017/Sep/22/converting-garmin-fit-to-csv/) was used to convert Garmin fit files to their GPS coordinates.
