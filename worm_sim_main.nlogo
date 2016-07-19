extensions [array csv table gis profiler]
__includes["environment.nls" "agents.nls" "gis-support.nls" "save-load-features.nls"]

globals[
  bs_run
  species_data
  monthly_data
  output_data
  grid_data            ;contains x,y coordinates of patches and population of turtles on that spot
  has_collected
  report_month
  area_list
  default_food_value
  temperature_table
  final_population
  max_pop
  pop_data
  ph_table
  temp_table
  xlow
  xhigh
  ylow
  yhigh
  export_file
  grid_file

  ;index positions of data in arrays
  ;month monitor species_number population density genetic diversity
]
to setup

  clear-all
  set bs_run false
  set year 0
  set ph_table table:make
  set temp_table table:make
  set area_list []
  set pop_data []
  set report_month 0
  set final_population 0
  set max_pop 0

  print "Loading temperature data..."
  load_temperature
  print "Setting up environment..."
  setup_environment
  print "Setting up agents..."
  setup_agents
  print "Done"
  print "Loading parameters..."

  load_ph_dependancy (word "simulations/" save_name "/input/parameters/pH-Table.csv") ph_table
  load_temp_dependancy (word "simulations/" save_name "/input/parameters/temp-Table.csv") temp_table

  set-default-shape sides "line"
  recolor_patches
  reset-ticks
end

to initialize_monitors
  print "Initializing monitors..."
  draw_monitor 0 60 0 60 "A"
  draw_monitor 240 300 0 60 "B"
  draw_monitor 240 300 240 300 "C"
  draw_monitor 0 60 240 300 "D"
  draw_monitor 120 180 120 180 "E"
  print "Done"
end

to calculate_bounds

  if ticks mod 7 = 0 [
    if count turtles > 0 [
      ask one-of turtles[
        set xlow xcor
        set xhigh xcor
        set ylow ycor
        set yhigh ycor
      ]
      ask turtles[
        if xcor < xlow [set xlow xcor]
        if xcor > xhigh [set xhigh xcor]
        if ycor < ylow [set ylow ycor]
        if ycor > yhigh [set yhigh ycor]
      ]
    ]
  ]
end

to setup_sim
  print "Loading from simulation files..."
  load_patches save_name
  load_agents save_name
  ;print "Finished loading environments"
end

to setup_bs
  setup
  set bs_run true
  setup_sim
  setup_export
end

to draw_river
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      set food-here 0
      set permeability speed_in_water
      set pcolor blue
    ]
    display
  ]
end

to draw_highway
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      set permeability road_speed
      set pcolor magenta
      set food-here default_food_value
    ]
    display
  ]
end

to draw_other
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      if (change: = "pH" or change: = "temperature difference and pH")
      [
        set ph patch_ph
      ]
      if (change: = "temperature difference" or change: = "temperature difference and pH")
      [
        set temp_diff_here temperature_difference
      ]
      recolor-patch
    ]
  ]
end

to pen
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      if (change: = "water")
      [
        set food-here 0
        set permeability speed_in_water
        set pcolor blue
      ]
      if (change: = "highway")
      [
        set food-here default_food_value
        set permeability road_speed
        set pcolor magenta

      ]
      if (change: = "pH" or change: = "temperature difference and pH")
      [
        set ph patch_ph
        recolor-patch
      ]
      if (change: = "temperature difference" or change: = "temperature difference and pH")
      [
        set temp_diff_here temperature_difference
        recolor-patch
      ]
    ]
    display
  ]
end

to setup_export
  set species_data [] ;list of collected info of each species for each monitor
  set monthly_data [] ;list of data collected each month
  set grid_data []    ;list of patches with worm population

  let export_header ["Month Number" "Monitor Number" "Species Number" "Population" "Density" "Genetic Diversity" "pH Tolerance" "Temperature Tolerance"]
  let grid_header (list"x-coordinate" "y-coordinate" "Population")

  set export_file (word "simulations/" save_name "/output/" temperature_tolerance "_" ph_tolerance "_" species_genetic_diversity "_" insertion_frequency ".csv")
  set grid_file (word "simulations/" save_name "/output/heatmap/grid_" temperature_tolerance "_" ph_tolerance "_" species_genetic_diversity "_" insertion_frequency ".csv" )


  if (not file-exists? export_file) [ ;initializes a file if it doesn't exist
    file-open export_file
    file-print csv:to-row export_header
    file-close
  ]

  if (not file-exists? grid_file) [
    file-open grid_file
    file-print csv:to-row grid_header
    file-close
  ]
end


to export_data

  ;exports grid data for heatmaps
  file-open grid_file
  foreach grid_data [ file-print csv:to-row ? ]
  file-print csv:to-row ["END SIM"]
  file-close

  ;exports user collected data
  file-open export_file
  foreach monthly_data [ file-print csv:to-row ? ]
  file-print csv:to-row ["END SIM"]
  file-close

  print "Exported simulation data to file"
end

;clears the arrays that are used to store matrix data
to clear_arrays

  set species_data []
  let monitor_idx_list n-values monitor_number [?]      ;(?) allows to create a list from 0 to monitor number
  foreach table:to-list species_list [                  ; --> [species_num, [species info] ]
    let current_species_number item 0 ?
    let species_info item 1 ?                           ;data to be exported from species_list can be changed in add_species function

    let species_matrix array:from-list monitor_idx_list ;m*n matrix of species data for every monitor
                                                        ;m = number of monitors, n = number of species charcteristics being collected
                                                        ;matrix-row --> MONTH MONITOR-NAME SPECIES-NUMBER POPULATION DENSITY SPECIES-INFO
    foreach monitor_idx_list [
      let matrix_row sentence (list report_month (item ? monitor_names) current_species_number 0 0) species_info ;resets population, density
      array:set species_matrix ? array:from-list matrix_row
    ]
    set species_data lput species_matrix species_data ;list of matrices
  ]

end

to collect_monthly_data

  if (day_of_month = (item current_month num_days - 1))[ ;clears arrays a day before collection
    clear_arrays
  ]

  ;saves monthly data to accumulutor list
  if (day_of_month = item current_month num_days)[

    ask patches with [being_monitored = true]
    [
      collect_monitor_data
    ]

    foreach species_data [
      let monitor_list (array:to-list ?)
      foreach monitor_list [
        set monthly_data lput (array:to-list ?) monthly_data
      ]
    ]

  ]

end

to random_insertions

  if (insertion_frequency > 0)[
    if (ticks mod (precision (365 / insertion_frequency) 0) = 0 and count (patches with [can-insert?]) > 0) [
      ;show year
      let species one-of table:keys species_list
      let spot one-of patches with [can-insert?];fishing_spots
      let number number_inserted
      add_species [pxcor] of spot [pycor] of spot number species species_genetic_diversity ph_tolerance temperature_tolerance 0;(item 0 spot) (item 1 spot) population species gd ph_tol temp_tol
    ]
  ]
end

to simulate_agents

  check_burrow

  ask adults [
    if (not burrow and pcolor != blue)[
      check_reproduction
      move
    ]
    update_thresholds
    check_death
  ]

  ask cocoons [
    check_if_hatch
  ]

end


to simulate_environment

  set global_temperature table:get temperature_table current_day

  if (current_day > 3) [
    set prev_days_temp (list
      table:get temperature_table (current_day - 2)
      table:get temperature_table (current_day - 1)
      global_temperature)
  ]

  set survival_prob 1
  ;  let day_prob 1
  ;  let mapped_temp 0

  ;gets cumulative probabilities of the past 3 days
  foreach prev_days_temp [

    ;    set mapped_temp precision (? + temp_shift) 1
    ;    ifelse table:has-key? temp_table mapped_temp [
    ;      set day_prob (item 0 table:get temp_table mapped_temp)
    ;    ][ set day_prob (item 0 table:get temp_table ?) ]
    ;    set survival_prob survival_prob * day_prob

    set survival_prob survival_prob * (item 0 table:get temp_table ?)
  ]

end

to save_heatmap
  let i min-pxcor
  let j min-pycor

  while [(i <= max-pxcor)]
  [
    while [(j <= max-pycor)]
    [
      ask patch i j
      [
        set density count turtles-here
        let info (list i j density)
        set grid_data lput info grid_data
        set j j + 1
      ]
    ]
    set j min-pycor
    set i i + 1
  ]

  ;saves screen shot of turtle densities
  ask turtles [hide-turtle]

  let prev Show:
  set Show: "turtle density"
  recolor_patches
  let filename (word "simulations/" save_name "/output/heatmap/" temperature_tolerance "_" ph_tolerance "_" species_genetic_diversity "_" insertion_frequency "_" ticks ".png")
  export-view filename
  set Show: prev
  recolor_patches

  ask turtles [show-turtle]

end


to collect_data

  if (ticks mod 1825 = 0) [
    save_heatmap
  ]

  if (year = number_of_years - 1) [
    collect_monthly_data
  ]
end

to-report check_stopping_conditions

  if (count turtles = 0) [
    export_data
    report true
  ]

  if (year = 10) [
    if (ticks mod 365 = 1)[
      set pop_data lput max_pop pop_data
      ;export_data
      set max_pop 0
      ;report true
    ]
  ]

  if (year = 20) [
    if (ticks mod 365 = 1)[
      set pop_data lput max_pop pop_data
      set max_pop 0
      ;report true
    ]
  ]

  if (year = number_of_years) [
    if (ticks mod 365 = 1)[
      set pop_data lput max_pop pop_data
      set max_pop 0
      report true
    ]
  ]

  report false

end

to calculate_maxPop
  let current_pop count adults
  if (current_pop > max_pop) [set max_pop current_pop]
end

to-report maxPop
  report pop_data
end

to-report finalPop
  report final_population / 365
end

to-report collected_data
  report monthly_data
end

to insertion_region [px pxhigh py pyhigh]
  ask patches
  [
    if (pxcor >= px and pxcor <= pxhigh and pycor >= py and pycor <= pyhigh and pcolor != grey)
      [
        set can-insert? true
        recolor-patch
      ]
  ]
end

to go

  ;    let filename (word "movie/" ticks ".png")
  ;    if (ticks mod 2 = 0) [
  ;      export-interface filename
  ;    ]
  ;    if (ticks = 1800) [stop]

  calculate_time

  random_insertions

  simulate_environment

  simulate_agents

  collect_data

  if check_stopping_conditions =  true [
    export_data
    ;        profiler:stop          ;; stop profiling
    ;        print profiler:report  ;; view the results
    ;        profiler:reset         ;; clear the data
    stop
  ]

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
286
71
1018
824
-1
-1
2.4
1
10
1
1
1
0
0
0
1
0
300
0
300
1
1
1
ticks
240.0

BUTTON
537
20
619
53
Initialize
setup\nsetup_export
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
469
21
528
54
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1053
24
1161
69
Day Number
day_num
17
1
11

PLOT
1038
131
1296
304
Worm Population for Current Year
Day Number
Population
0.0
365.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy day_num count adults\nif (day_num = 365) [clear-plot]"
"pen-1" 1.0 0 -2674135 true "" "plotxy day_num count adults with [parent_breed = 0]\nif (day_num = 365) [clear-plot]"
"pen-2" 1.0 0 -11221820 true "" "plotxy day_num count adults with [parent_breed = 1]\nif (day_num = 365) [clear-plot]"
"pen-3" 1.0 0 -2064490 true "" "plotxy day_num count adults with [parent_breed = 2]\nif (day_num = 365) [clear-plot]"
"pen-4" 1.0 0 -955883 true "" "plotxy day_num count adults with [parent_breed = 3]\nif (day_num = 365) [clear-plot]"
"pen-5" 1.0 0 -5825686 true "" "plotxy day_num count adults with [parent_breed = 4]\nif (day_num = 365) [clear-plot]"

SLIDER
19
203
270
236
ph_tolerance
ph_tolerance
-0.5
0.5
0
0.1
1
NIL
HORIZONTAL

SLIDER
19
245
270
278
temperature_tolerance
temperature_tolerance
-2
2
0
0.1
1
NIL
HORIZONTAL

MONITOR
1054
73
1161
118
Population Count
count adults
17
1
11

PLOT
1038
312
1296
485
Worm Population over Years
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -11221820 true "" "plotxy year count adults"

MONITOR
1169
73
1267
118
Cocoon Count
count cocoons
17
1
11

INPUTBOX
170
588
269
648
starting_day
150
1
0
Number

MONITOR
1169
24
1267
69
Daily Temp *C
global_temperature
2
1
11

CHOOSER
20
603
166
648
obstacle_shape
obstacle_shape
"circle" "rectangle" "mountain" "monitor"
0

SLIDER
19
322
270
355
speed
speed
0
1
0.55
0.01
1
NIL
HORIZONTAL

INPUTBOX
19
22
140
82
save_name
defaultRun
1
0
String (reporter)

SLIDER
20
703
270
736
patch_pH
patch_pH
0
14
7
0.1
1
NIL
HORIZONTAL

CHOOSER
20
551
166
596
Show:
Show:
"pH" "depth" "temperature" "monitor" "turtle density" "insertion points"
0

TEXTBOX
23
90
133
108
Species Controls
13
0.0
1

SLIDER
19
284
270
317
species_genetic_diversity
species_genetic_diversity
0
1
0
0.1
1
NIL
HORIZONTAL

CHOOSER
19
115
270
160
species_number
species_number
1 2 3 4 5
0

BUTTON
19
443
102
476
Add
mouse_add_species
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
170
551
269
584
Recolor Patches
recolor_patches
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
783
143
817
Save Environment
save_patches save_name
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
150
783
270
817
Load Environment
load_patches save_name
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
108
443
182
476
Save
save_agents save_name
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
187
443
270
476
Load
load_agents save_name
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
743
270
776
temperature_difference
temperature_difference
-10
10
3
0.5
1
NIL
HORIZONTAL

BUTTON
20
509
102
542
Draw
pen
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
108
509
182
543
Select
edit_environment
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
187
509
270
544
Modify
recolor-selected
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
22
485
182
503
Environment Controls\n
13
0.0
1

CHOOSER
20
653
270
698
change:
change:
"pH" "temperature difference" "pH and temperature difference" "highway" "water" "insertion point"
3

BUTTON
624
20
714
53
Load GIS
setup_gis\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
19
165
270
198
worm_population
worm_population
0
500
25
5
1
NIL
HORIZONTAL

PLOT
1039
488
1295
650
X Boundaries
NIL
NIL
0.0
300.0
0.0
10.0
true
false
"" "calculate_bounds"
PENS
"high" 1.0 0 -16777216 true "" "plotxy xlow ticks"
"low" 1.0 0 -7500403 true "" "plotxy xhigh ticks"

PLOT
1039
656
1295
819
Y Boundaries
NIL
NIL
0.0
10.0
0.0
300.0
true
false
"" ""
PENS
"low" 1.0 0 -16777216 true "" "plot ylow"
"high" 1.0 0 -7500403 true "" "plot yhigh"

SLIDER
19
361
270
394
insertion_frequency
insertion_frequency
0
104
0
1
1
/year
HORIZONTAL

BUTTON
719
20
818
53
Hide Worms
ask turtles [hide-turtle]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
823
20
917
53
Show Worms
ask turtles[show-turtle]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
382
20
462
53
Setup
;profiler:start\nsetup\nsetup_sim\n;load_agents save_name\nsetup_export
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
148
22
270
82
number_of_years
15
1
0
Number

SLIDER
19
399
270
432
number_inserted
number_inserted
0
50
5
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

# HOW TO USE IT

##Setting Up a Simulation:
If parameters and GIS data are located in the proper folders, then pressing the "Setup Simulation" button will load them into the NetLogo world.  Then, to add worms, adjust the sliders to the desired parameters, select the number of worms to add to the simulation, and press the Add button.  If you want to add worms to random locations within a selected region, press "Select" and select an area, then press add. Note: after adding worms, click somewhere within the environment again while "Select" is still pressed in order to deselect the region. Once agents have been added, a simulation can be started by pressing "Go" and the simulation will run until "Go" is pressed again, it has simulated 30 years of invasion, or all of the worms have died. The "starting_day" box controls what day of the starting year the simulation starts on.

<b>Note</b>: Any data collected from the simulation will be appended to the end of the exisiting output files. You will have to manually remove existing files from the 'simulations/{save_name}/output' folder if you want new files.


##Species Controls:
###Add:

The "Add" button allows users to place worms in the NetLogo world.  The "worm_popoulation" slider at the top of the species controls how many worms are placed when the user presses "Add". If only "Add" is selected, when the user clicks, the worms will be inserted at that location.  If a region is selected with "Select", the worms will be randomly distributed within that region.  The Interface will prevent users from placing worms where there is water or a rock outcropping within a selected box; it will not do this when the user adds with a mouse click.


##Environment Controls:
The user has the ability to manipulate an existing environment or create an entire environemnt of their own.
###Draw:
If "Draw" is selected, and "change:" is set to water or highway, then the user can drag their mouse around the netlogo world to draw either of these features.  If the mouse seems unresponsive, make sure the "view updates" chooser on the top bar of the Interface panel is set to continuous. Tip: drawing slowly will be much more accurate. If "change:" is set to anything other than water or highway, the "Draw" button will not draw anything.


Note: Make sure to not have "Draw" selected at the same time as "Add" or "Select"

###Select:
When "Select" is on, clicking and dragging on the NetLogo world will create a box around a selected region. Once drawn, users can modify the parameters of this box in a variety of ways.

####pH and/or Temperature:
If the user wants to change the pH and/or temperature within the box, they should adjust the patch_ph and temperature_difference sliders to the desired parameters. Then, select the desired shape from the "obstacle_shape" box. Choosing "rectangle" will fill the entire selected box with the chosen parameters. "Circle" will fill in a circle with diameter of the shorter side of the box and a center at the center of the box with the parameters in the box. "Mountain" will draw a circle, but instead of uniform parameters, it will create a gradient from the current parameters, on the edges, to slider parameters, in the center.

####Monitors:
Choosing "Monitor" in the "obstacle_shape" box will draw a new monitor in the selected box; it will not modify any of the parameters in the box, regardless of what is selected in the "change:" box. After choosing the desired settings, press "Modify" to implement them. Note: After use, deselect the area by clicking on any point in the NetLogo world.

####Insertion Regions:
If "change:" is set to "insertion_points", the patches contained by the obstacle will be encoded as locations where worms can spawn when "Random_Insertions?" is turned on. When a random insertion occurs, every individual patch will have an equal chace of having worms spawn. E.g. a big square will have higher chance of having worms spawn at random insertion invervals than a smaller square.



##How to Upload Data:
GIS data on soil should be retrieved from the USDA Web Soil Survey (http://websoilsurvey.sc.egov.usda.gov/App/WebSoilSurvey.aspx).
GIS highway data: provide link
Historical temperature data was retrieved from PRISM (http://www.prism.oregonstate.edu/historical/)
Data from these files should be stored in the "simulations" folder in another folder with the *save_name* that will be used with the data. The folder structure should mirror the folder structure of the provided GIS data.
For more information on how to download and set up GIS data in the NetLogo world, see the provided "How to download GIS data.docx" document.

##How to Modify Paramters:
In a folder there exists parameters.  If you want to modify the parameters, modify the .csv with the corresponding parameters that need to be modified. Parameters for a particular save_name are found in the filepath simulations/*save_name*/input/parameters/
The .csv files have values for pH/temperature and the corresponding survivability/hatchability rates of worms and cocoons.

##Save/Load Features:
The buttons "Save" and "Load" will save or load the locations and parameters of worms in the simulation with "save_name"
The buttons "Save Environment" and "Load Environment" will save or load the current characteristics of every individual patch. This has the effect of saving the pH, depth and moisture on each patch and locations with water, rock outcroppings, highways, insertion points and monitors.
It is reccomended that the user saves the environment every time before they make a change so they can easily revert to the previous state if they make a mistake--there is no undo button.

##Using BehaviorSpace for Multiple Simulations:
BehaviorSpace is a useful tool in NetLogo to run multiple simulations simultaneously. To run a BehaviorSpace experiment, click on "Tools -> BehaviorSpace". You can either edit the existing experiment, or create your own.  The first box will allow you to choose which variable to change in your simulations, follow the instructions below the box to choose which values are used in the simulations.  If you want to run a simulation multiple times with the same parameters, include the line ["save_number" [1 1 *number_of_runs*]] with the variables.  The following commands must be in the corresponding boxes for a simulation to work properly.

####Reporters:
maxPop
####Setup commands:
setup
setup_sim
load_agents save_name
####Go commands:
go

##Other Buttons/Information:
###What is a Turtle?
A turtle is an agent that moves around the world.  In this model, worms and cocoons are both turtles.
###Inspect Turtles/Patches
By right clicking on a turtle/patch, users can observe the agent's attributes and location.
###Show/Hide Worms
Hide turtles makes the turtles invisible to the user.  This feature is useful if the user wants to observe what the traits of patches with very high densities of turtles. Turtles will still continue their usual processes, but not be visible to the user.
Show turtles will make all hidden turtles visible again.

##Useful Functions:
Using the following commands in the "observer>" line of the command center will enable the user to have more precise control over the environment they are manipulating. To use one of these functions, first type the one-word command in the observer line, followed by the desired parameters, substituted for the words in italics.
###initialize_monitors
This command automatically generates population density monitors in the four corners and center of the NetLogo world.
###draw_monitor *x_low x_high y_low y_high*
Draws a rectangular population density monitor with corners at (x_low, y_low) (x_low, y_high) (x_high, y_low) and (x_high, y_high). All coordinates need to be integers because they refer to patch coordinates.
###insertion_region *x_low x_high y_low y_high*
Draws a rectangular insertion region with corners at *(x_low, y_low), (x_low, y_high), (x_high, y_low) and (x_high, y_high)*. All coordinates need to be integers because they refer to patch coordinates.
###insert_worms *x y number species_number*
Inserts *number* worms at location *(x, y)* with the attributes of the species with *species_number*.


# THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cyan_worm
true
0
Polygon -11221820 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

magenta_worm
true
0
Polygon -5825686 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

orange_worm
true
0
Polygon -955883 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

pink_worm
true
0
Polygon -2064490 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

red_worm
true
0
Polygon -2674135 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

violet_worm
true
0
Polygon -8630108 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="insertions" repetitions="3" runMetricsEveryStep="true">
    <setup>setup_bs</setup>
    <go>go</go>
    <steppedValueSet variable="insertion_frequency" first="0" step="3" last="10"/>
  </experiment>
  <experiment name="test" repetitions="3" runMetricsEveryStep="true">
    <setup>setup_bs</setup>
    <go>go</go>
    <enumeratedValueSet variable="ph_tolerance">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="roads" repetitions="10" runMetricsEveryStep="false">
    <setup>setup_bs</setup>
    <go>go</go>
    <enumeratedValueSet variable="save_name">
      <value value="&quot;roadTest&quot;"/>
      <value value="&quot;defaultRun&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ph" repetitions="3" runMetricsEveryStep="false">
    <setup>setup_bs</setup>
    <go>go</go>
    <steppedValueSet variable="ph_tolerance" first="-0.2" step="0.1" last="0.1"/>
  </experiment>
  <experiment name="temp" repetitions="3" runMetricsEveryStep="false">
    <setup>setup_bs</setup>
    <go>go</go>
    <steppedValueSet variable="temperature_tolerance" first="-0.5" step="0.5" last="0.5"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
