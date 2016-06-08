extensions [array csv table gis]
__includes["environment.nls" "agents.nls" "gis-support.nls"]

globals[
  species_data
  monthly_data
  output_data
  has_collected
  report_month
  area_list
  default_food_value
  temperature_table
  ;index positions of data in arrays
  ;month monitor species_number population density genetic diversity
]
to setup
  ;clear-all

  print "Setting up environment..."
  ;setup_environment
  print "Done"
  ;setup_gis
  print "Setting up agents..."
  setup_agents
  print "Done"

  set species_data [] ;list of collected info of each species for each monitor
  set monthly_data [] ;list of data collected each month
  set area_list []
  set report_month 0

  set-default-shape sides "line"
  ;setup_sim
  recolor_patches
  reset-ticks
end


to setup_sim
 ;setup

  print "Loading from simulation files..."
  load_patches "ham1"
  load_agents "ham1"
  load_monitors "ham1"
  print "Done Loading"
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
      set pcolor turquoise
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
        set pcolor turquoise

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

to save_obstacles [name]
  let filename1 (word "data/parameters/myobstacle"  name ".csv")
  csv:to-file filename1 obstacle_list
  print "Saved to file"
end

to load_obstacles [name]
  let filename (word "data/parameters/myobstacle"  name ".csv")
  set obstacle_list csv:from-file filename
  print "Loaded from file: "
  print obstacle_list
  ;;draw_obstacles
end

to save_patches [name]
  save_monitors name
  save_obstacles name
  let filename (word "data/parameters/mypatches" name ".csv")
  let i min-pxcor
  let j min-pycor
  carefully [file-delete filename] []
  while [(i <= max-pxcor)]
  [
   while [(j <= max-pycor)]
   [
     ask patch i j
     [
       let info (list i j ph food-here permeability local_death_threshold temp_diff_here pcolor)
       file-open filename
       file-print csv:to-row info
       file-close
       set j j + 1
     ]
   ]
   set j min-pycor
   set i i + 1
  ]

end

to load_patches [name]
  load_obstacles name
  let filename (word "data/parameters/mypatches" name ".csv")
  let data csv:from-file filename
  foreach (data)
  [
    ask patch (item 0 ?) (item 1 ?)
    [
      set ph item 2 ?
      set food-here item 3 ?
      set permeability item 4 ?
      set local_death_threshold item 5 ?
      set temp_diff_here item 6 ?
      set being_monitored false
      set pcolor item 7 ?
    ]
  ]
  load_monitors name
  calculate_temp
  recolor_patches
end

to save_agents [name]
  export_data name
  let filename1 (word "data/parameters/specieslist" name ".csv")
  let data []
  foreach table:to-list species_list [ ;converts table into listto store as csv
    set data lput (sentence item 0 ? array:to-list item 1 ?) data
    ]
  csv:to-file filename1 data

  let filename (word "data/parameters/myagents"  name ".csv")

  carefully [file-delete filename] []
  ask turtles
  [
       let info (list xcor ycor parent_breed shape wait_period hatch_temp genetic_diversity max_temp_resist low_temp_resist max_ph_resist)
       file-open filename
       file-print csv:to-row info
       file-close
  ]
  print "Saved to file"
end

to load_agents [name]
  ;load_monitors name
  let filename1 (word "data/parameters/specieslist"  name ".csv")
  let filename (word "data/parameters/myagents" name ".csv")
  let data []
  set species_list table:make
  set data csv:from-file filename1
  foreach data [table:put species_list item 0 ? array:from-list (list item 1 ? item 2 ?)]
  print "Loaded from file: "
  print species_list
  set data csv:from-file filename
  foreach (data)
  [
    create-adults 1 [
    setxy item 0 ? item 1 ?
    set parent_breed item 2 ?
    set size 1
    set shape item 3 ?
    set maturation 70
    set wait_period item 4 ?
    set hatch_temp item 5 ?
    set stamina 5
    set genetic_diversity item 6 ?
    set max_temp_resist item 7 ?
    set low_temp_resist item 8 ?
    set max_ph_resist item 9 ?
    set color (item parent_breed color_list)
    set death_threshold normal_death_threshold
    set reprod_threshold normal_reproduction_rate
   ]
  ]
end

to load_temperature
  let filename (word "data/parameters/temperaturelist.csv")
  file-open filename
  set temperature_table table:make
  let i 0
  while [i < 8]
  [
   let nothing csv:from-row file-read-line
   set i i + 1
  ]
  let days_since_start 0
  while [ not file-at-end? ]
  [
    let row (csv:from-row file-read-line)
    let row_entry (item 1 row)
    ;show row_entry
    table:put temperature_table days_since_start row_entry
    set days_since_start days_since_start + 1
  ]


  file-close

end

to save_monitors [name]
  let filename (word "data/parameters/mymonitors" name ".csv")
  let i min-pxcor
  let j min-pycor
  carefully [file-delete filename] []
  file-open filename
  while [(i <= max-pxcor)]
  [
   while [(j <= max-pycor)]
   [
     ask patch i j
     [
       let info (list i j being_monitored monitor_index monitor_size monitor_number)
       file-open filename
       file-print csv:to-row info
       file-close
       set j j + 1
     ]
   ]
   set j min-pycor
   set i i + 1
  ]
end

to load_monitors [name]
  let filename (word "data/parameters/mymonitors" name ".csv")
  let data csv:from-file filename
  foreach (data)
  [
    ask patch (item 0 ?) (item 1 ?)
    [
      set being_monitored item 2 ?
      set monitor_index item 3 ?
      set monitor_size item 4 ?
    ]
    set monitor_number item 5 ?
  ]
  update_monitor_area
  recolor_patches
end

to export_data [name]
  let filename (word "data/output/simulation" name ".csv")
  csv:to-file filename monthly_data
  print "Exported simulation data to file"
end

to clear_arrays

   set species_data []
   let monitor_list n-values monitor_number [?] ;(?) allows to create a list from 0 to monitor number
   foreach table:to-list species_list [
     let current_species_number item 0 ?
     ;allows for the storage of other species characteristics
     ;let current_species_info array:to-list item 1 ?

     ;n*m matrix of species data for every monitor
     let species_matrix array:from-list monitor_list  ;n = number of species charcteristics being collected, m = number of monitors
     foreach monitor_list [
       array:set species_matrix ? array:from-list (list report_month ? current_species_number 0 0) ;resets population, density
     ]
     set species_data lput species_matrix species_data ;list of matrices
   ]
    set has_collected false
end



to go

  calculate_time
  if (year = 30) [
    export_data save_number
    stop
    ]
  if (count turtles = 0) [
    export_data save_number
    stop]

 if (day_of_month = (item current_month num_days - 1))[ ;clears arrays a day before collection
   clear_arrays
  ]

  if (ticks mod (periods-in-day) = 0) [
    set current_day current_day + 1
    set global_temperature table:get temperature_table current_day
    ;calculate_temp
    ;update_organic_matter

    ask cocoons [
      check_if_hatch
    ]
  ]

  ask adults [
    ;update_speed
    if (ticks mod (periods-in-day) = 0) [
      update_maturity
      update_thresholds
      check_reproduction
      ]

    move

    ;set food-here food-here + organic-regen
  ]
  ask patches with [being_monitored = true]
  [
    if (day_of_month = item current_month num_days)[
      if (has_collected = false)[
        collect_data
      ]
    ]
  ]
   ;saves monthly data to accumulutor list
  if (day_of_month = item current_month num_days)[
    if (has_collected = false) [
      ;show species_data
      foreach species_data [
        let monitor_list (array:to-list ?)
        foreach monitor_list [
          set monthly_data lput (array:to-list ?) monthly_data
        ]
      ]
      print "Monthly data: "
      show monthly_data
      set report_month report_month + 1
      set has_collected true
    ]
  ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
255
10
1067
793
-1
-1
2.0
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
400
0
375
1
1
1
ticks
1000.0

BUTTON
12
10
78
43
Setup
setup
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
95
10
154
44
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
1084
533
1192
578
Day Number
day_num
17
1
11

PLOT
1072
638
1311
802
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
13
220
214
253
ph_tolerance
ph_tolerance
-10
10
0
1
1
%
HORIZONTAL

SLIDER
12
257
212
290
max_reproduction_rate
max_reproduction_rate
0
10
8.5
0.1
1
NIL
HORIZONTAL

SLIDER
12
297
211
330
temperature_tolerance
temperature_tolerance
0
100
25
1
1
NIL
HORIZONTAL

MONITOR
1085
582
1192
627
Population Count
count adults
17
1
11

PLOT
1306
439
1570
612
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
1200
582
1298
627
Cocoon Count
count cocoons
17
1
11

INPUTBOX
8
57
87
117
starting_day
150
1
0
Number

MONITOR
1200
532
1295
577
Daily Temp *C
global_temperature
2
1
11

CHOOSER
1082
40
1322
85
obstacle_shape
obstacle_shape
"circle" "rectangle" "mountain" "monitor"
1

SLIDER
12
412
211
445
speed
speed
0
0.5
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
14
568
47
718
January
January
-20
40
-10
1
1
*C
VERTICAL

SLIDER
54
569
87
719
February
February
-20
40
-8
1
1
*C
VERTICAL

SLIDER
93
569
126
719
March
March
-20
40
-2
1
1
*C
VERTICAL

SLIDER
134
570
167
720
April
April
-20
40
4
1
1
*C
VERTICAL

SLIDER
175
570
208
720
May
May
-20
40
11
1
1
*C
VERTICAL

SLIDER
215
571
248
721
June
June
-20
40
15
1
1
*C
VERTICAL

SLIDER
13
724
46
874
July
July
-20
40
18
1
1
*C
VERTICAL

SLIDER
51
725
84
875
August
August
-20
40
17
1
1
*C
VERTICAL

SLIDER
91
726
124
876
September
September
-20
40
17
1
1
*C
VERTICAL

SLIDER
132
725
165
875
October
October
-20
40
7
1
1
*C
VERTICAL

SLIDER
174
725
207
875
November
November
-20
40
1
1
1
*C
VERTICAL

SLIDER
215
725
248
875
December
December
-20
40
-6
1
1
*C
VERTICAL

INPUTBOX
1207
303
1324
385
save_name
abcd
1
0
String (reporter)

SLIDER
1083
138
1322
171
patch_pH
patch_pH
0
14
10.2
0.1
1
NIL
HORIZONTAL

CHOOSER
1083
303
1202
348
Show:
Show:
"pH" "food" "temperature" "monitor"
0

TEXTBOX
10
129
120
147
Species Control
13
0.0
1

SLIDER
13
335
209
368
species_genetic_diversity
species_genetic_diversity
0
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
12
374
211
407
species_hatch_temperature
species_hatch_temperature
0
25
12
1
1
NIL
HORIZONTAL

CHOOSER
12
453
112
498
species_number
species_number
1 2 3 4 5
0

BUTTON
127
463
208
496
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
1082
352
1203
385
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
1082
388
1204
421
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
1206
388
1325
421
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
14
505
103
538
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
124
505
210
538
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
1083
174
1322
207
temperature_difference
temperature_difference
-10
10
-6
0.5
1
NIL
HORIZONTAL

TEXTBOX
13
545
206
575
Global Temperature Control
12
0.0
1

TEXTBOX
1153
18
1303
36
Environment Controls\n
12
0.0
1

BUTTON
1082
214
1201
247
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
1205
214
1322
247
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
1082
254
1322
287
Edit Patch
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

SLIDER
1081
436
1243
469
save_number
save_number
0
100
0
1
1
NIL
HORIZONTAL

CHOOSER
1083
89
1322
134
change:
change:
"pH" "temperature difference" "pH and temperature difference" "water" "highway"
1

TEXTBOX
13
545
206
575
Global Temperature Control
12
0.0
1

TEXTBOX
1153
18
1303
36
Environment Controls\n
12
0.0
1

SLIDER
1083
475
1244
508
save_number
save_number
0
100
0
1
1
NIL
HORIZONTAL

CHOOSER
1083
89
1322
134
change:
change:
"pH" "temperature difference" "both"
1

INPUTBOX
13
152
168
212
worm_population
1000
1
0
Number

BUTTON
167
10
256
43
Setup GIS
ca\nload_temperature\nsetup_environment\nsetup_gis\nsetup\n
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
103
54
309
87
NIL
ca\nsetup_environment\nsetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

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
  <experiment name="Hypothesis-1 Test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
setup_sim</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="save_number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
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
