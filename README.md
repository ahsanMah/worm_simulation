# worm_simulation
Simulation of crazy worms using NetLogo
Ahsan Mahmood and George Armstrong

Make sure to download all of the contents from the Google Drive folder into the same folder.  

worm_sim_main.nlogo can be opened int NetLogo, which can be downloaded from https://ccl.northwestern.edu/netlogo/download.shtml

Information on how to use the worm simulator is on the “Info” tab of the NetLogo interface.

Information on how to download and use GIS data is available in the document “How to download GIS data.docx”

How to use plot.command:
Use this to plot figures. If it is in the same folder and simulations have been run, it should work (will change a little when support for multiple simulations with freedom to adjust simulation is incorporated)

How to use interpolate.command:
Use this to fill in the blanks between known parameters.

How to download GIS data:

Soil:
1.	Begin by opening the USDA Web Soil Survey (http://websoilsurvey.sc.egov.usda.gov/App/WebSoilSurvey.aspx)
2.	After zooming to the area you would like to study, you must select and Area of Interest (AOI) with the AOI tool on the Interactive Map panel. Try to keep the AOI as close to a square as possible. Note that the Web Soil Survey limits the size of AOI’s.


3.	 Once you have selected your AOI, you can go the “Download Soils Data” tab and click “Create Download Link”. Once your download link has been created, download it by clicking it.  

Once the file has been downloaded and unzipped, copy the “spatial” folder from the contents and paste it into the folder: simulations/save_name/input/soil/

4.	Next, you must create the map key. Go to the Soil Properties and Qualities Tab. When you select a trait and press “View Rating”, a table with the values of that trait will appear, as well as a key to understand the symbols on the map. Now begin by creating a file in excel, or another text editor, titled “map_key.csv”:
    a.	The first column of the .csv should be the map unit symbol.  It is important that this is typed just as it is in the table where it is given.
    b.	The second column should have the map unit name
    c.	The third, fourth, and fifth columns should contain the ratings for the following traits, respectively:
        i.	Soil Chemical Properties -> pH
        ii.	Soil Qualities and Features -> Depth to Any Soil Restrictive Layer
        iii.	Soil Physical Properties -> Water Content, 15 bar
    d.	When completed, save the file to folder: simulations/save_name/input/soil






Temperature:
1.	Open the PRISM climate group’s data explorer (http://prism.nacse.org/explorer/)
2.	 Find the area that you want data for within the explorer
3.	Adjust the settings in the window to match the settings in the picture below, within your chosen region. The start date should be January 1, but the year is up to you, depending on when/how long you would like to simulate.
4.	After you have chosen the correct settings, click “Retrieve Time Series” then click “Download Time Series”
5.	Once the data has been downloaded as a .csv, save it as “temperaturelist.csv” in the folder: simulations/save_name/input/environment/


Highways:
1.	Go to the following URL to download highway GIS data http://nationalmap.gov/small_scale/atlasftp.html?openChapters=chptrans#chptrans
2.	In the table, pull down the “Transportation” tab and find the “Roads, One-million Scale” data then download the shapefile.
3.	After downloading, copy the contents of the download to simulations/save_name/input/roads/ (as shown below)
4.	If you have copies of the files already saved for other simulations, they can be copy and pasted into the same file path of a new save_name



