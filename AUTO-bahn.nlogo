globals [
  loop-counter
  roads
  lane-ycord
  lane-one
  lane-two
  lane-three
  max-speed-limit
  min-speed-limit
  lead-car
  lead-car-moves
  prev-xcor
  prev-ycor
  car-ahead
  lane-fast
  lane-slow
  lane-medium
]

breed [ dividers divider ]
breed [ cars car ]
breed [ lanes lanee ] 

cars-own [
  speed
  lane
  previous-x
  agressive?
  
    ; basic properties of the car
  
  current-speed ; what is my current speed
  preferred-speed ; what is my preferred speed ( 1 lowest -> 10 highest )
  current-lane ; what lane i am in ( 3 fastest -> 2 -> 1 slowest) 
  cooperativeness-rating ; how willing am i to let someone in my lane? ( 1 lowest -> 10 highest )
  next-lane ; what is his next choice?
  
  ; conditions of the adjacent lanes
  
  
  ; TODO
]

;*********************** Lanes *********************************
  
lanes-own [
  
  ; attributes
	current-congestion ; // how full are we?
  max-speed ; max
  min-speed ; min
  emission-rating ; cars traveling in this lane emit this for their emissions
  y-pos ; where are we on the y axis
]
  
  ; methods

  to update-lane ; lane procedure
    ; update all of lane parameters here
    let congestion 0
    let laneY y-pos
    ; find all cars on this y coordinate
      ask cars [
        if (pycor = laneY)
        [ set congestion congestion + 1 ]
      ]
    show congestion
    set current-congestion congestion    
    
  end
    
    
    ; ******* group of lanes ********
    
    
    to update-lanes
      ask lanes [
        update-lane
      ]
    end
    
      
      
    to setup-lanes
      let line (max-pycor * 2 / 3)
      set lane-one (min-pycor + (line / 2))
      set lane-two 0
      set lane-three (max-pycor - (line / 2))
      
			create-lanes 3 [
        set current-congestion 0
      ] ; create 3 lanes 
      
      ; update each based on their number
      
      set lane-fast 4
      set lane-medium 3
  		set lane-slow 2
      
      ask lanee lane-fast [ 
        set max-speed 10
        set min-speed 7
        set emission-rating 3
        set y-pos lane-three
      ] ; fast-lane

      ask lanee lane-medium [ 
        set max-speed 6
        set min-speed 4
        set emission-rating 2
        set y-pos lane-two
      ] ; medium-lane
      
      ask lanee lane-slow [ 
        set max-speed 3
        set min-speed 1
        set emission-rating 1
        set y-pos lane-one
      ] ; slow-lane
      
    end
    
    
    ;*********************** End Lanes *********************************

      
 to change-lanes ; car procedure
    		let y 0
  
        if(next-lane = lane-fast) [
          ask lanee lane-fast [ set y y-pos ] 
        ]
        if(next-lane = lane-medium) [
          ask lanee lane-medium [ set y y-pos ] 
        ]
        if(next-lane = lane-slow) [
          ask lanee lane-slow [ set y y-pos ] 
        ]
        
        set current-lane next-lane

        setxy xcor y
    
  end
      
  
  


        
        
        
        
        
;*********************** SETUP & GO *********************************


to setup
  clear-all
  setup-display
  set max-speed-limit 1
  set min-speed-limit 0
  setup-lanes
  setup-cars
  update-lanes ; determine congestion based on cars placed
  watch lead-car
  
  reset-ticks
end

to go
  update-lanes ; lanes need to know their parameters
  
  
  
  ask lead-car [ set prev-xcor xcor  set prev-ycor ycor ]
  cars-drive
  tick
  ask lead-car [ set lead-car-moves (lead-car-moves + distancexy prev-xcor prev-ycor) ]
;  plot-data
  
end


  
  
to cars-drive
  ; vroom vroom
  
  
  ; update all of my parameters
  ask cars [
    set speed 1
    fd speed
  ]  
  
  ; send out all of my arguments
  
  
  
  
  
  
  ; everyone should know what theyre doing by now
  
  
  
  
  
  
  
  ; let them do what they decided
  
   ask cars [
    change-lanes
  ]  
  
end
  
;*********************** CAR SETUP *********************************
  	
to setup-cars
  if total-cars > world-width [
    user-message (word
      "There are too many cars for the amount of road.  Please decrease the NUMBER-OF-CARS slider to below "
      (world-width + 1) " and press the SETUP button again.  The setup has stopped.")
    stop
  ]
  let line (max-pycor * 2 / 3)

  set lane-one (min-pycor + (line / 2))
  set lane-two 0
  set lane-three (max-pycor - (line / 2))
  
  set-default-shape turtles one-of ["car-east"]
  setup-traffic 90 lane-three lane-two lane-one 

  set lead-car one-of cars
  ask lead-car [
    set color sky
    if (Lane-Shift) [
      set agressive? true
      set label 0
    ]
  ]
end

    
to setup-traffic [ direction fast-lane medium-lane slow-lane ]
    create-cars total-cars [
    set color 15
    set heading direction
    set next-lane fast-lane
    ifelse ((random 2) = 0) [
      set lane-ycord fast-lane
    ] [
      ifelse ((random 2) = 0) [
      	set lane-ycord medium-lane
      ] [
        set lane-ycord slow-lane
      ]
    ]

    setxy random-xcor lane-ycord

    set agressive? false
    if (Lane-Shift) [
      set previous-x max-pxcor
      if ((random 2) = 0) [ ; roughly 1 in 1 get to be lane changers
        set agressive? true
        set label 0
      ]
    ]

    set speed 0.1 + random-float 0.9
    separate-cars
    avoid-collision
  ]

end

 ;*********************** CAR SETUP *********************************

  
to separate-cars ;; turtle procedure
  if any? other turtles-here [
    fd 2
    separate-cars
  ]
end

to avoid-collision
  set loop-counter (loop-counter + 1)
  let max-iterations 25
  if any? other cars-here [
    forward random 2
    if (loop-counter < 25) [
      avoid-collision
      separate-cars
    ]
  ]
end
to locate-empty-road-spot
  move-to one-of roads with [ not any? turtles-on self ]
end

to speed-up  ; car procedure
  set color 15
  ifelse speed < (max-speed-limit)
    [  set speed speed + car-acceleration ]
    [ set speed max-speed-limit ]
end

to slow-down  ; car procedure
  set color 15
  set speed (speed - car-deceleration)
  if speed < min-speed-limit [
    set speed min-speed-limit
  ]
end
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
;*********************** DISPLAY *********************************

to setup-display
  setup-dividers
  setup-grass
end

to setup-median
  ask patches [
    if (pycor = 0)
    [ set pcolor 9.9 ]
  ]
end

to setup-dividers
  let line (max-pycor * 2 / 3)
  
  setup-divider (max-pycor - line)
  setup-divider (min-pycor + line)
end

to setup-divider [ y ]
  create-dividers 1 [
    set shape "line"
    set color yellow   ; lanes on California roads are white
    setxy min-pxcor y ; start on the far left
    set heading 90    ; draw towards the right
  ]
  let line-length 2   ; default
  let line-spacing 1  ; default
  if (not Lane-Shift) [     ; user can choose if cars are allowed to change lanes
    set line-length 1
    set line-spacing 0
  ]

  repeat (world-width / (line-length + line-spacing)) [
    ask dividers [
      paint-line line-length line-spacing
    ]
  ]
  ask dividers [ die ] ;don't need the line painting agents any longer
end

to paint-line [ line-length line-spacing ]
  pen-down
  forward line-length
  pen-up
  forward line-spacing
end

to setup-grass
  ask patches [
    if (pycor > (max-pycor - 1) or pycor < (min-pycor + 1))
    [ set pcolor [0 255 0] ]
  ]
end
