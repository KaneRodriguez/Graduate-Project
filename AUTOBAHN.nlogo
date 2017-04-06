;; ADD assumptions

globals [
  loop-counter
  roads
  lane-ycord
  lane-fast-id
  lane-medium-id
  lane-slow-id
  max-speed-limit
  min-speed-limit
  lead-car
  lead-car-moves
  prev-xcor
  prev-ycor
  car-ahead
	lane-fast-ypos
  lane-medium-ypos
	lane-slow-ypos
  debug
  conflicts

  worldEmissionLevel
]

extensions [table]

breed [ dividers divider ]
breed [ cars car ]
breed [ lanes lanee ]


cars-own [
  speed
  previous-x
  agressive?


    ; basic properties of the car

  current-speed ; what is my current speed
  preferred-speed ; what is my preferred speed ( 1 lowest -> 10 highest )
  current-lane-id ; what lane ID am i in
  cooperativeness-rating ; how willing am i to let someone in my lane? ( 1 lowest -> 10 highest )
  next-lane-id ; what is his next choice?
  next-speed;

  ;        conditions of the adjacent lanes

  ; are the lanes above and below even feasible?
  laneBelowFeasible
  laneAboveFeasible


  ;        adjacent vehicles available through - getCarAbove/Below/Ahead getCarAheadTooSlow
 	recommendedAction

  ; 		objectives TODO



  ; dummy cars
  dummy

  ; *********************************   environmental conditions    *******************************************

  laneAboveInBounds
  laneBelowInBounds

  laneAboveOccupied
  laneBelowOccupied
  spotAheadOccupied

  laneAboveClaimed
  laneBelowClaimed
  spotAheadClaimed

  abovePreferredSpeed
  belowPreferredSpeed
  atPreferredSpeed

  wantFasterLane
  wantSlowerLane

  laneBelowRelativeCongestion
  currentLaneRelativeCongestion
  laneAboveRelativeCongestion

  laneAboveRelativeEmission
  laneBelowRelativeEmission
  currentLaneRelativeEmission

  speedDifferential
  normalizedCooperativeness

  ; *********************************   other conditions    *******************************************


  ; does action involve lane change? (true or false)
  laneChange

  ; IMPORTANT - what priority are we
  currentPriority

  ; what did i choose
  chosenAction

  ; speed -- how aggressive am i ( .1 to 1 )
  agressive

]

lanes-own [

  ; attributes
	current-congestion ; // how full are we?
  max-speed ; max
  min-speed ; min
  emission-rating ; cars traveling in this lane emit this for their emissions
  y-pos ; where are we on the y axis
]

;*********************** Lanes *********************************

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

      set lane-slow-ypos (min-pycor + (line / 2))
      set lane-medium-ypos 0
      set lane-fast-ypos (max-pycor - (line / 2))

			create-lanes 3 [
        set current-congestion 0
      ] ; create 3 lanes

      ; update each based on their number

      set lane-fast-id 4
      set lane-medium-id 3
      set lane-slow-id 2

      ask lanee lane-fast-id [
        set max-speed 1.0
        set min-speed .7
        set emission-rating 3
        set y-pos lane-fast-ypos
      ] ; fast-lane

      ask lanee lane-medium-id [
        set max-speed .6
        set min-speed .4
        set emission-rating 2
        set y-pos lane-medium-ypos
      ] ; medium-lane

      ask lanee lane-slow-id [
        set max-speed .3
        set min-speed .1
        set emission-rating 1
        set y-pos lane-slow-ypos
      ] ; slow-lane

    end


    ;*********************** End Lanes *********************************

;*********************** Cars *********************************

      ; methods

      to getRecommendedAction ; car procedure
                   ; matchSpeedOfApproachingCar moveUpLane moveDownLane speedUp slowDown staySameSpeed
        set recommendedAction ""



        ;; < since NOT wantSlowerLane AND NOT wantFasterLane AND NOT abovePreferredSpeed AND NOT belowPreferredSpeed AND (getCarAhead = nobody); we are in the speed we want, stay >

        if ( NOT wantSlowerLane AND NOT wantFasterLane AND NOT abovePreferredSpeed AND NOT belowPreferredSpeed AND (getCarAhead = nobody) ) [
          set recommendedAction "staySameSpeed"
        ]

        if ( NOT wantSlowerLane AND NOT wantFasterLane AND belowPreferredSpeed AND (getCarAhead = nobody) ) [
          set recommendedAction "speedUp"
        ]

        if ( NOT wantSlowerLane AND NOT wantFasterLane AND abovePreferredSpeed and (getCarAhead = nobody ) ) [
          set recommendedAction "slowDown"
        ]

        if ( wantFasterLane AND getLaneAboveAvailability ) [
          set recommendedAction "moveUpLane"
        ]

        if ( wantSlowerLane AND getLaneBelowAvailability ) [
          set recommendedAction "moveDownLane"
        ]

        if ( ( getCarAhead != nobody ) AND NOT getLaneAboveAvailability AND NOT getLaneBelowAvailability ) [
          set recommendedAction "matchApproachingCarSpeed"
        ]

        if ( getCarAheadTooSlow AND getLaneAboveAvailability AND belowPreferredSpeed) [
          set recommendedAction "moveUpLane"
        ]
        if( (getCarAhead != nobody) and [current-speed] of getCarAhead > preferred-speed ) [
          set recommendedAction  "slowDown"
        ]
        if recommendedAction = "" [
            ; uh-oh, we don't know what to do
            if ( getCarAhead != nobody ) [ ; is there a car ahead?
                set recommendedAction "matchApproachingCarSpeed"
            ]
        ]





        ;; if( any? other cars-on patch-here ) [ displayCarStatus ]
      end
			to-report getLaneAboveAvailability

        if( laneAboveFeasible and (getCarAbove = nobody) ) [
          report true
        ]
        report false
        end

        to-report getLaneBelowAvailability

        if( laneBelowFeasible and (getCarBelow = nobody) ) [
          report true
        ]
        report false
        end

          to-report getCarAheadTooSlow
            let carAhead getCarAhead
            let currentLaneMin 0
            let carAheadTooSlow false

            ask lanee current-lane-id [
              set currentLaneMin min-speed
            ]

            if( carAhead != nobody ) [
             ; is this car going too slow for his lane??
              let speedOfCarAhead 0
              ask carAhead [
                set speedOfCarAhead current-speed
              ]

              if( speedOfCarAhead < currentLaneMin ) [
                set carAheadTooSlow true
              ]
            ]
            report carAheadTooSlow
          end





      to evaluateConditions ; car procedure
        evaluateLaneConditions ; gives me info about what lanes i want and what is possible
      end



          to displayCarStatus
            show "laneId (4-fast.3-med,2-slow)"
            show current-lane-id
            show "laneBelowFeasible:"
            show laneBelowFeasible
            show "laneAboveFeasible:"
            show laneAboveFeasible
            show "currentSpeed:"
            show current-speed
            show "preferredSpeed:"
            show preferred-speed
            show "abovePreferredSpeed:"
            show abovePreferredSpeed
            show "belowPreferredSpeed:"
            show belowPreferredSpeed
            show "wantFasterLane:"
            show wantFasterLane
            show "wantSlowerLane:"
            show wantSlowerLane
            show "CarAhead:"
            show getCarAhead
            show "recommendedAction:"
            show recommendedAction
          end

        to evaluateLaneConditions ; car procedure
                  ; i want to know :

        ; are the lanes above or below me feasible?

        ifelse ycor = lane-slow-ypos
        [ set laneBelowFeasible false]
        [ set laneBelowFeasible true ]

        ifelse ycor = lane-fast-ypos
        [ set laneAboveFeasible false]
        [ set laneAboveFeasible true ]

        ; am i above or below my current speed?

        ifelse current-speed > preferred-speed
        [ set abovePreferredSpeed true]
        [ set abovePreferredSpeed false ]

        ifelse current-speed < preferred-speed
        [ set belowPreferredSpeed true]
        [ set belowPreferredSpeed false ]

        ; are the speeds of this lane to my liking?

        let myLaneMax 0
        let myLaneMin 0

        ask lanee current-lane-id [
          set myLaneMax max-speed
          set myLaneMin min-speed
        ]

        ifelse preferred-speed > myLaneMax
        [ set wantFasterLane true]
        [ set wantFasterLane false ]

        ifelse (preferred-speed < myLaneMin)
        [ set wantSlowerLane true]
        [ set wantSlowerLane false ]

        if debug [
          show "-- Car Evaluating Conditions --"
          displayCarStatus
        ]
        end

        to executeActions ; car procedure

          if debug [
           show "-- Car Executing Choice --"
            displayCarStatus
          ]

          executeChoice recommendedAction
          ifelse (not dummy) [
            adjustLane ; CALL before changing speed
            adjustSpeed
          ] [
           forward current-speed
          ]
        end

        to executeChoice [ choice ]
          if( choice = "matchApproachingCarSpeed") [
           ; matchSpeedOfApproachingCar moveUpLane moveDownLane speedUp slowDown staySameSpeed
            matchApproachingCarSpeed
          ]
          if( choice = "moveUpLane") [
            moveUpLane
          ]
          if( choice = "moveDownLane") [
            moveDownLane
          ]
          if( choice = "speedUp") [
            speedUp
          ]
          if( choice = "slowDown") [
            slowDown
          ]
          if( choice = "staySameSpeed") [
            staySameSpeed
          ]
        end


          to matchApproachingCarSpeed  ; car procedure
            let newSpeed 0
            let carAhead getCarAhead
            ifelse( carAhead != nobody ) [
              ask carAhead [
              set newSpeed current-speed
              ]
            ] [
              set newSpeed current-speed
            ]

            set next-speed newSpeed
          end



    ;*********************** End Cars *********************************


;*********************** SETUP & GO *********************************


to setup
  clear-all
  set debug false
  setup-display
  setup-lanes ; do before cars, cars drive in lanes, duh
  setup-cars
  update-lanes ; determine congestion based on cars placed
  watch lead-car
  reset-ticks
end

to go
  update-lanes ; lanes need to know their parameters before the cars can ask them about it!
  updateWorldEmission

  ask lead-car [ set prev-xcor xcor  set prev-ycor ycor ]
  cars-drive
  tick
  ask lead-car [ set lead-car-moves (lead-car-moves + distancexy prev-xcor prev-ycor) ]
;  plot-data

end

to updateWorldEmission
  let totalEmission 0

        ask lanee lane-fast-id [
          set totalEmission (totalEmission + emission-rating * current-congestion)
      ] ; fast-lane

      ask lanee lane-medium-id [
        set totalEmission (totalEmission + emission-rating * current-congestion)
      ] ; medium-lane

      ask lanee lane-slow-id [
        set totalEmission (totalEmission + emission-rating * current-congestion)
      ] ; slow-lane

   set worldEmissionLevel totalEmission
end


to cars-drive
  ; vroom vroom

   if debug [
     show "---- New Driving Session  ----"
    ]

  ask cars [
    if not dummy [
      determineFeasibleActions
      decideBestAction

    ]
  ]

  ask cars [
    if not dummy [
      if(laneChange) [
        resolveArguments
      ]
      waitForTurnEnd
    ]
  ]

  ask cars [
    ifelse not dummy [
      performAction
    ] [
     fd current-speed
    ]
  ]

end

  ;; ********************* Expert System **************************




  to determineFeasibleActions

  ifelse ycor = lane-slow-ypos
  [ set laneBelowInBounds false]
  [ set laneBelowInBounds true ]

  ifelse ycor = lane-fast-ypos
  [ set laneAboveInBounds false]
  [ set laneAboveInBounds true ]

  ; am i above or below my current speed?

  ifelse current-speed > preferred-speed
  [ set abovePreferredSpeed true]
  [ set abovePreferredSpeed false ]

  ifelse current-speed < preferred-speed
  [ set belowPreferredSpeed true]
  [ set belowPreferredSpeed false ]

  ifelse current-speed = preferred-speed
  [ set atPreferredSpeed true]
  [ set atPreferredSpeed false ]

  ; are the speeds of this lane to my liking?

  let myLaneMax 0
  let myLaneMin 0

  ask lanee current-lane-id [
    set myLaneMax max-speed
    set myLaneMin min-speed
  ]

  ifelse preferred-speed > myLaneMax
  [ set wantFasterLane true]
  [ set wantFasterLane false ]

  ifelse (preferred-speed < myLaneMin)
  [ set wantSlowerLane true]
  [ set wantSlowerLane false ]

  ; are lanes above, below, or ahead occupied? // NOTE: Call this after the bounds are determined for lanes

  ifelse (getCarAhead != nobody)
  [ set spotAheadOccupied true]
  [ set spotAheadOccupied false ]

  ifelse (getCarAbove != nobody)
  [ set laneAboveOccupied true]
  [ set laneAboveOccupied false ]

  ifelse (getCarBelow != nobody)
  [ set laneBelowOccupied true]
  [ set laneBelowOccupied false ]

; are lanes above, below, or ahead claimed? This is set when we win/lose arguments, leave them alone for now

  ; laneAboveClaimed
  ; laneBelowClaimed
  ; spotAheadClaimed

  ; determine the normalized cooperativeness, speedDifferential, lane above and below relative congestion/emission // NOTE: Call this after the bounds are determined for lanes

; *************** Congestion *************8



  ifelse (laneBelowInBounds) [
       let worldCongestion getWorldCongestion
       let itsCongestion 0

       ask lanee (current-lane-id - 1) [
         set itsCongestion current-congestion
       ]

       ifelse (worldCongestion > 0) [
         set laneBelowRelativeCongestion (itsCongestion / worldCongestion)
       ] [
         set laneBelowRelativeCongestion 0
       ]
  ] [
      set laneBelowRelativeCongestion 0
  ]

  ifelse (laneAboveInBounds) [
       let worldCongestion getWorldCongestion
       let itsCongestion 0

       ask lanee (current-lane-id + 1) [
         set itsCongestion current-congestion
       ]

       ifelse (worldCongestion > 0) [
         set laneAboveRelativeCongestion (itsCongestion / worldCongestion)
       ] [
         set laneAboveRelativeCongestion 0
       ]
  ] [
      set laneAboveRelativeCongestion 0
  ]

    ifelse (true) [  ;; got lazy, dont judge me, Ctl+C, Ctl+V master
       let worldCongestion getWorldCongestion
       let itsCongestion 0

       ask lanee (current-lane-id) [
         set itsCongestion current-congestion
       ]

       ifelse (worldCongestion > 0) [
         set currentLaneRelativeCongestion (itsCongestion / worldCongestion)
       ] [
         set currentLaneRelativeCongestion 0
       ]
  ] [
      set currentLaneRelativeCongestion 0
  ]




   ; *************** Emission *************8



  ifelse (laneBelowInBounds) [
       let worldEmission getWorldEmission
       let itsEmission 0

       ask lanee (current-lane-id - 1) [
         set itsEmission emission-rating
       ]

       ifelse (worldEmission > 0) [
         set laneBelowRelativeEmission (itsEmission / worldEmission)
       ] [
         set laneBelowRelativeEmission 0
       ]
  ] [
      set laneBelowRelativeEmission 0
  ]

  ifelse (laneAboveInBounds) [
       let worldEmission getWorldEmission
       let itsEmission 0

       ask lanee (current-lane-id + 1) [
         set itsEmission emission-rating
       ]

       ifelse (worldEmission > 0) [
         set laneAboveRelativeEmission (itsEmission / worldEmission)
       ] [
         set laneAboveRelativeEmission 0
       ]
  ] [
      set laneAboveRelativeEmission 0
  ]

    ifelse (true) [  ;; got lazy, dont judge me, Ctl+C, Ctl+V master
       let worldEmission getWorldEmission
       let itsEmission 0

       ask lanee (current-lane-id) [
         set itsEmission emission-rating
       ]

       ifelse (worldEmission > 0) [
         set currentLaneRelativeEmission (itsEmission / worldEmission)
       ] [
         set currentLaneRelativeEmission 0
       ]
  ] [
      set currentLaneRelativeEmission 0
  ]


  ; ******* bleh - speed differential and normalizedCooperativeness

  let worldMax getWorldMaxSpeed
  ifelse ( worldMax > 0) [
    set speedDifferential ( (preferred-speed - current-speed) / getWorldMaxSpeed )
  ] [
    set speedDifferential 0
  ]


  if currentPriority = "emission" [
      set normalizedCooperativeness (1 - abs speedDifferential + 1 - currentLaneRelativeEmission + (cooperativeness-rating) / 10 )

      set normalizedCooperativeness min list normalizedCooperativeness 1
    ]
  if currentPriority = "congestion" [
      set normalizedCooperativeness (1 - abs speedDifferential + 1 - currentLaneRelativeCongestion + (cooperativeness-rating) / 10 )

      set normalizedCooperativeness min list normalizedCooperativeness 1
    ]
  if currentPriority = "travelTime" [
      set normalizedCooperativeness (1 - abs speedDifferential + (cooperativeness-rating) / 10 )

      set normalizedCooperativeness min list normalizedCooperativeness 1
    ]

end

  ; *********** Possible Actions ************8

  to-report canMoveUp
    ; 3 conditions - Bounds, Occupation, Claim
    if(laneAboveInBounds AND not laneAboveOccupied AND not laneAboveClaimed) [
      report true
    ]
    report false
end

  to-report canMoveDown
    ; 3 conditions - Bounds, Occupation, Claim
    if(laneBelowInBounds AND not laneBelowOccupied AND not laneBelowClaimed) [
      report true
    ]
    report false
end

   to-report canMaintainSpeed
    ; as long as spot ahead isnt occupied or claimed
    if(not spotAheadOccupied AND not spotAheadClaimed) [
      report true
    ]
    report false
end

   to-report canDecelerate
    ; current speed not below lane min : NOTE - Could change! Could have no requirements to stop!
    let currentMax 0
    let currentMin 0

    ask lanee current-lane-id [
      set currentMax max-speed
      set currentMin min-speed
    ]

    if(current-speed > currentMin) [
     report true
    ]
    report false

end

   to-report canAccelerate
    ; current speed not above lane max : NOTE - Could change! Could have no requirements to stop!
    let currentMax 0
    let currentMin 0

    ask lanee current-lane-id [
      set currentMax max-speed
      set currentMin min-speed
    ]

    if(current-speed < currentMax) [
     report true
    ]
    report false

end

  ; *********** End Possible Actions ************8


  ; *********** Perform Actions ************8

            to speedUp ; car procedure
            set next-speed (current-speed + car-acceleration)
            adhereToLaneRules "max"
          end
          to slowDown ; car procedure
            set next-speed (current-speed - car-deceleration)
            adhereToLaneRules "min"
          end
          to staySameSpeed ; car procedure
            set next-speed current-speed
          end
          to moveUpLane ; car procedure
            set next-lane-id (current-lane-id + 1)
            adhereToLaneRules "min"
          end

            to moveDownLane ; car procedure
            set next-lane-id (current-lane-id - 1)
            adhereToLaneRules "max"
          end

          to adhereToLaneRules [ ruleType ]
            let currentMax 0
            let currentMin 0

            ask lanee next-lane-id [
              set currentMax max-speed
              set currentMin min-speed
            ]

            if(next-speed > currentMax and ruleType = "max") [
              set next-speed currentMax
            ]
            if(next-speed < currentMin and ruleType = "min") [
              set next-speed currentMin
            ]
          end

  ; *********** End Perform Actions ************8

  to decideBestAction
    let decidedAction ""
    if( currentPriority = "travelTime" ) [
      set decidedAction decideBestTravelTimeAction
    ]

    if( currentPriority = "emission" ) [
      set decidedAction decideBestEmissionAction
    ]

    if( currentPriority = "congestion" ) [
      set decidedAction decideBestCongestionAction
    ]
    if decidedAction = "" [
     ; still no decision? Just arbitrarily, but conservatively, pick one!
     ; OR just stop!
      set decidedAction "decelerate"
    ]

    set chosenAction decidedAction
    let argumentation false
    if argumentation [
      ifelse chosenAction = "moveUp" OR chosenAction = "moveDown" [
        set laneChange true
      ] [
        set laneChange false
      ]
    ]
end

  to-report decideBestTravelTimeAction

    let currentLaneMin 0
    let currentLaneMax 0
    let speedFactor travelTimeAggresiveness

    ask lanee current-lane-id [
      set currentLaneMin min-speed
      set currentLaneMax max-speed
    ]

    ; fast people ignore their preferred-speed
    if( currentLaneMax < (preferred-speed + speedFactor ) )[
      ;; this lane is too slow for us
      if canMoveUp [
        report "moveUp"
      ]
      if canAccelerate [
        report "accelerate"
      ]

    ]

  ;; is this lane too fast for me?
    if( currentLaneMin > (preferred-speed + speedFactor ) )[
      ;; this lane is too slow for us
      if canMoveDown [
        report "moveDown"
      ]
      if canDecelerate [
        report "decelerate"
      ]

    ]

  if ( current-speed = (preferred-speed + speedFactor) ) and canMaintainSpeed [
    report "maintainSpeed"
  ]

   report ""

end

  to-report decideBestEmissionAction
    let currentLaneMin 0
    let currentLaneMax 0
    let speedFactor emissionFriendliness

    ask lanee current-lane-id [
      set currentLaneMin min-speed
      set currentLaneMax max-speed
    ]

    ; we are willing to go below our preferred speed in order to go to a less emission lane
; if the lane i am in has a max that is below my adjusted preferred speed, go up
    if( currentLaneMax < (preferred-speed - speedFactor ) )[
      ;; this lane is too slow for us
      if canMoveUp [
        report "moveUp"
      ]
      if canAccelerate [
        report "accelerate"
      ]

    ]

  ;; is this lane too fast for me?
    if( currentLaneMin > (preferred-speed - speedFactor ) )[
      ;; this lane is too slow for us
      if canMoveDown [
        report "moveDown"
      ]
      if canDecelerate [
        report "decelerate"
      ]

    ]

  if ( current-speed = (preferred-speed - speedFactor) ) and canMaintainSpeed [
    report "maintainSpeed"
  ]

   report ""
end

  to-report decideBestCongestionAction
    let currentLaneMin 0
    let currentLaneMax 0
    let speedFactor congestionAwareness


    ask lanee current-lane-id [
      set currentLaneMin min-speed
      set currentLaneMax max-speed
    ]

; if the lane i am in has a max that is below my adjusted preferred speed, go up

    if( currentLaneMax < ( preferred-speed ) ) [
      ;; this lane is too slow for us
      ;; but should we move up if its congested? we want a relative congestion of .333 (each lane the same)

      ;; dont want to move to a more congested lane, or a lane that is relatively congested (half)
      if canMoveUp and ( laneAboveRelativeCongestion < congestionAwareness OR laneAboveRelativeCongestion < currentLaneRelativeCongestion )  [
        report "moveUp"
      ]
    ]

  ;; is this lane too fast for me?
    if( currentLaneMin > (preferred-speed ) )[
      ;; this lane is too slow for us
      if canMoveDown  and ( laneBelowRelativeCongestion < congestionAwareness OR laneBelowRelativeCongestion < currentLaneRelativeCongestion )[
        report "moveDown"
      ]


    ]

  if belowPreferredSpeed [
   if canAccelerate [
        report "accelerate"
      ]
  ]
  if belowPreferredSpeed [
   if canDecelerate [
        report "decelerate"
      ]
  ]

  if canMaintainSpeed [
    report "maintainSpeed"
  ]

   report ""
end

  to resolveArguments
    if (laneChange) [
      determineFeasibleActions
      decideBestAction
    ]

end

  to waitForTurnEnd

end

  to performAction
    ;; 5 possible actions

    ifelse chosenAction = "moveUp" [ moveUpLane ]
    [ ifelse chosenAction = "moveDown" [ moveDownLane ]
    [ ifelse chosenAction = "accelerate" [ speedUp ]
    [ ifelse chosenAction = "decelerate" [ slowDown ]
      [ ifelse chosenAction = "maintainSpeed" [ staySameSpeed ] []

    ] ] ] ]

    adjustLane ;; call before adjusting speed
    adjustSpeed

end



  ; ******* Evaluating Environmental Conditions ***************;
  to-report getWorldMaxSpeed
    let worldMax 0
   ask lanee lane-fast-id [
     set worldMax max-speed
   ]
   report worldMax
end
  to-report getWorldCongestion
    let totalWorldCongestion 0

      ask lanee lane-fast-id [
        set totalWorldCongestion (totalWorldCongestion + current-congestion)
      ] ; fast-lane

      ask lanee lane-medium-id [
        set totalWorldCongestion (totalWorldCongestion + current-congestion)
      ] ; medium-lane

      ask lanee lane-slow-id [
        set totalWorldCongestion (totalWorldCongestion + current-congestion)
      ] ; slow-lane

      report totalWorldCongestion

end

  to-report getWorldEmission
    let totalWorldEmission 0

      ask lanee lane-fast-id [
        set totalWorldEmission (totalWorldEmission + emission-rating)
      ] ; fast-lane

      ask lanee lane-medium-id [
        set totalWorldEmission (totalWorldEmission + emission-rating)
      ] ; medium-lane

      ask lanee lane-slow-id [
        set totalWorldEmission (totalWorldEmission + emission-rating)
      ] ; slow-lane

      report totalWorldEmission

end
      to-report getCarAhead ; car procedure
            let carVar nobody
            let myX xcor
            ifelse ( any? other cars-on patch-here ) [

              ask other cars-on patch-here [
                if( xcor > myX ) [
                 set carVar self
                ]

              ]
            ] [
            ;; nooone in my spot, so look further ahead
              ask cars-on patch-ahead 1 [
                set carVar self
              ]
            ]
            report carVar
          end

          to-report getCarAbove ; car procedure
            let carVar nobody
            let y 0

            if(laneAboveInBounds) [

              ask lanee (current-lane-id + 1) [
              	set y y-pos
            	]

              if( any? cars-on patch xcor y ) [
                ask cars-on patch xcor y [
                  set carVar self
                ]

              ]

            ]
            report carVar
          end

          to-report getCarFarAbove ; car procedure
            let carVar nobody
            let y 0

            if(current-lane-id = lane-slow-id) [

              ask lanee (current-lane-id + 2) [
              	set y y-pos
            	]

              if( any? cars-on patch xcor y ) [
                ask cars-on patch xcor y [
                  set carVar self
                ]

              ]

            ]
            report carVar
          end
          to-report getCarCuttingOff
            let carVar nobody
            let y 0

            if(current-lane-id = lane-slow-id) [
              ask lanee (current-lane-id + 1) [
              	set y y-pos
            	]
              if( any? cars-on patch (xcor - 1) y ) [
                ask cars-on patch xcor y [
                  set carVar self
                ]
              ]
            ]
            if(current-lane-id = lane-fast-id) [
              ask lanee (current-lane-id - 1 ) [
              	set y y-pos
            	]
              if( any? cars-on patch (xcor - 1) y ) [
                ask cars-on patch xcor y [
                  set carVar self
                ]
              ]
            ]
            report carVar
          end
          to-report getCarBelow; car procedure
            let carVar nobody
            let y 0

            if(laneBelowInBounds) [
              ask lanee (current-lane-id - 1) [
              	set y y-pos
            	]

              if( any? cars-on patch xcor y ) [
                ask cars-on patch xcor y [
                  set carVar self
                ]

              ]

            ]
            report carVar
          end

          to-report getCarFarBelow; car procedure
            let carVar nobody
            let y 0

            if(current-lane-id = lane-fast-id) [
              ask lanee (current-lane-id - 2) [
              	set y y-pos
            	]

              if( any? cars-on patch xcor y ) [
                ask cars-on patch xcor y [
                  set carVar self
                ]

              ]

            ]
            report carVar
          end

  to initializeCarParameters
    ; * Note: does not initialize all yet

  set laneAboveInBounds false
  set laneBelowInBounds false

  set laneAboveOccupied false
  set laneBelowOccupied false
  set spotAheadOccupied false

  set laneAboveClaimed false
  set laneBelowClaimed false
  set spotAheadClaimed false

  set abovePreferredSpeed false
  set belowPreferredSpeed false
  set atPreferredSpeed false

  set wantFasterLane false
  set wantSlowerLane false

  set laneBelowRelativeCongestion false
  set currentLaneRelativeCongestion false
  set laneAboveRelativeCongestion false

  set laneAboveRelativeEmission false
  set laneBelowRelativeEmission false
  set currentLaneRelativeEmission false

  set speedDifferential 0
  set normalizedCooperativeness 0

  set laneChange false

  set currentPriority "none"

end
  to displayCar
    show "-------------------- Car Parameters ----------------"
    show self

  show "laneAboveInBounds"
  show laneAboveInBounds
  show "laneBelowInBounds"
  show laneBelowInBounds

  show "laneAboveOccupied"
  show laneAboveOccupied
  show "laneBelowOccupied"
  show laneBelowOccupied
  show "spotAheadOccupied"
  show spotAheadOccupied

  show "laneAboveClaimed"
  show laneAboveClaimed
  show "laneBelowClaimed"
  show laneBelowClaimed
  show "spotAheadClaimed"
  show spotAheadClaimed

  show "abovePreferredSpeed"
  show abovePreferredSpeed
  show "belowPreferredSpeed"
  show belowPreferredSpeed
  show "atPreferredSpeed"
  show atPreferredSpeed

  show "wantFasterLane"
  show wantFasterLane
  show "wantSlowerLane"
  show wantSlowerLane

  show "laneBelowRelativeCongestion"
  show laneBelowRelativeCongestion
  show "currentLaneRelativeCongestion"
  show currentLaneRelativeCongestion
  show "laneAboveRelativeCongestion"
  show laneAboveRelativeCongestion

  show "laneAboveRelativeEmission"
  show laneAboveRelativeEmission
  show "laneBelowRelativeEmission"
  show laneBelowRelativeEmission
  show "currentLaneRelativeEmission"
  show currentLaneRelativeEmission

  show "speedDifferential"
  show speedDifferential
  show "normalizedCooperativeness"
  show normalizedCooperativeness

  show "laneChange"
  show laneChange

  show "currentPriority"
  show currentPriority
end
  ; ******* Performing Actions ***************

            to adjustSpeed  ; car procedure
            ; this is where we ACTUALLY adjust the speed
            let carAhead getCarAhead
            let carAheadX 0
            let carAheadSpeed 0
            if( carAhead != nobody ) [
              ask carAhead [
                set carAheadX xcor
                set carAheadSpeed next-speed
              ]
              if(xcor + next-speed > (carAheadX + carAheadSpeed) ) [
                set next-speed (.9 * carAheadSpeed )
              ]
            ]

            set current-speed next-speed
            fd current-speed
          end


 to adjustLane ; car procedure

   ; changing lanes

   	if debug [
        show "-- Car Changing Lanes --"
        show "From CurrentLane:"
      show current-lane-id
      	show "To NextLane:"
      show next-lane-id
      ]

    		let y 0

   		if(next-lane-id = lane-fast-id) [
          set y lane-fast-ypos
        ]
   		if(next-lane-id = lane-medium-id) [
          set y lane-medium-ypos
        ]
   		if(next-lane-id = lane-slow-id) [
          set y lane-slow-ypos
        ]

   		set current-lane-id next-lane-id

        setxy xcor y

   	if debug [
        show "Lane is now: "
        show current-lane-id
      ]

  end





  ;*********************** SETUP Car Placement and Initialization of Parameters *********************************

to setup-cars

  let line (max-pycor * 2 / 3)

  set-default-shape turtles one-of ["car-east"]
  setup-traffic 90

  set lead-car one-of cars
  ask lead-car [
    set color sky
    if (Lane-Shift) [
      set agressive? true
    ]
  ]
end


to setup-traffic [ direction ]
  let laneOneAmount 0
  let laneTwoAmount 0
  let laneThreeAmount 0
  let dummyCount 0
  let emissionAmount emissionCars
  let congestionAmount congestionCars
  let speedAmount speedCars

    create-cars congestionAmount [

      initializeCarParameters ; doesnt include all for now

      ; give cars random current and preferred speeds
      set current-speed ( (random 10 + 1) / 10)
      set preferred-speed ( (random 10 + 1) / 10 )

      set currentPriority "congestion"

      ifelse( dummyCount < dummy-cars ) [
       set dummy true
       set color white
       set dummyCount (dummyCount + 1)
      ] [ set dummy false
     set color 15 ]
set color brown
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)


      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0 and laneOneAmount < world-width) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
        set laneOneAmount (laneOneAmount + 1)
      ] [
        ifelse ((random 2) = 0  and laneOneAmount < world-width) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id
          set laneTwoAmount (laneTwoAmount + 1)
        ] [
          ifelse (laneThreeAmount < world-width) [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
          set laneThreeAmount (laneThreeAmount + 1)
          ] [
            ;; way too many cars!
            user-message "Way too many cars!"
            stop
          ]
        ]
      ]

      set next-lane-id current-lane-id ; make him stay where he is for now

      if debug [
        show "---- Car Initialization ----"
      ]

      ; randomly place them on a position on the lane

      setxy random-xcor chosenLaneYPos

      ; fiddle with how they are placed on their lane
      separate-cars
      avoid-collision
  ]
create-cars emissionAmount [

      initializeCarParameters ; doesnt include all for now

      ; give cars random current and preferred speeds
      set current-speed ( (random 10 + 1) / 10)
      set preferred-speed ( (random 10 + 1) / 10 )

      set currentPriority "emission"

      ifelse( dummyCount < dummy-cars ) [
       set dummy true
       set color white
       set dummyCount (dummyCount + 1)
      ] [ set dummy false
     set color 15 ]
set color green
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)


      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0 and laneOneAmount < world-width) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
        set laneOneAmount (laneOneAmount + 1)
      ] [
        ifelse ((random 2) = 0  and laneOneAmount < world-width) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id
          set laneTwoAmount (laneTwoAmount + 1)
        ] [
          ifelse (laneThreeAmount < world-width) [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
          set laneThreeAmount (laneThreeAmount + 1)
          ] [
            ;; way too many cars!
            user-message "Way too many cars!"
            stop
          ]
        ]
      ]

      set next-lane-id current-lane-id ; make him stay where he is for now

      if debug [
        show "---- Car Initialization ----"
      ]

      ; randomly place them on a position on the lane

      setxy random-xcor chosenLaneYPos

      ; fiddle with how they are placed on their lane
      separate-cars
      avoid-collision
  ]
  create-cars speedAmount [

      initializeCarParameters ; doesnt include all for now

      ; give cars random current and preferred speeds
      set current-speed ( (random 10 + 1) / 10)
      set preferred-speed ( (random 10 + 1) / 10 )

      set currentPriority "travelTime"

      ifelse( dummyCount < dummy-cars ) [
       set dummy true
       set color white
       set dummyCount (dummyCount + 1)
      ] [ set dummy false
     set color 15 ]
set color red
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)


      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0 and laneOneAmount < world-width) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
        set laneOneAmount (laneOneAmount + 1)
      ] [
        ifelse ((random 2) = 0  and laneOneAmount < world-width) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id
          set laneTwoAmount (laneTwoAmount + 1)
        ] [
          ifelse (laneThreeAmount < world-width) [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
          set laneThreeAmount (laneThreeAmount + 1)
          ] [
            ;; way too many cars!
            user-message "Way too many cars!"
            stop
          ]
        ]
      ]

      set next-lane-id current-lane-id ; make him stay where he is for now

      if debug [
        show "---- Car Initialization ----"
      ]

      ; randomly place them on a position on the lane

      setxy random-xcor chosenLaneYPos

      ; fiddle with how they are placed on their lane
      separate-cars
      avoid-collision
  ]
end


  ; ********** basic setup collission avoidance ***************

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
    if (loop-counter < 50) [
      avoid-collision
      separate-cars
    ]
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
@#$#@#$#@
GRAPHICS-WINDOW
6
10
1244
332
-1
-1
24.12
1
10
1
1
1
0
1
0
1
-25
25
-6
6
0
0
1
ticks
30.0

BUTTON
8
400
72
433
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
76
400
139
433
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

SLIDER
11
596
182
629
car-deceleration
car-deceleration
0
0.9
0.9
.01
1
NIL
HORIZONTAL

SLIDER
10
557
182
590
car-acceleration
car-acceleration
0
.04
0.04
.0001
1
NIL
HORIZONTAL

SWITCH
7
362
139
395
Lane-Shift
Lane-Shift
1
1
-1000

PLOT
762
367
1119
598
Congestion Levels
time
congestion
0.0
1000.0
0.0
1.0
true
true
"" ""
PENS
"Fast Lane Congestion" 1.0 0 -7500403 true "" "plot [current-congestion] of lanee lane-fast-id"
"Slow Lane Congestion" 1.0 0 -2674135 true "" "plot [current-congestion] of lanee lane-slow-id"
"Medium Lane Congestion" 1.0 0 -955883 true "" "plot [current-congestion] of lanee lane-medium-id"

MONITOR
323
368
491
413
Focused car's speed
[speed] of lead-car
3
1
11

MONITOR
154
368
321
413
Focused car's average speed
lead-car-moves / ticks
3
1
11

TEXTBOX
248
543
490
584
Car Green : Emission\nCar Red : Travel Time\nCar Brown : Congestion
10
0.0
0

SLIDER
245
590
417
623
dummy-cars
dummy-cars
0
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
256
459
449
492
travelTimeAggresiveness
travelTimeAggresiveness
0
1
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
257
423
429
456
emissionFriendliness
emissionFriendliness
0
1
0.0
.05
1
NIL
HORIZONTAL

SLIDER
9
480
181
513
emissionCars
emissionCars
0
30
30.0
1
1
NIL
HORIZONTAL

SLIDER
9
518
181
551
congestionCars
congestionCars
0
30
0.0
1
1
NIL
HORIZONTAL

SLIDER
9
443
181
476
speedCars
speedCars
0
30
24.0
1
1
NIL
HORIZONTAL

SLIDER
255
502
430
535
congestionAwareness
congestionAwareness
0
1
0.0
0.05
1
NIL
HORIZONTAL

PLOT
504
368
752
596
Emission Levels
time
 emission
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot worldEmissionLevel"

@#$#@#$#@
## WHAT IS IT?

A multi-lane traffic simulator with the ability to toggle the divider between lanes to allow cars to change lanes.

## HOW IT WORKS

Each car is designated at creation as "agressive" or not, those that are can change lanes when another car is directly ahead instead of slowing down.

## HOW TO USE IT

Click "Setup", then "Go".

## THINGS TO NOTICE

The labels on each car show how many times they have changed lanes.

How the "wave" phenomena of jams is changed by the users selected options.

## THINGS TO TRY

Changing the car distance (the space between cars).

## EXTENDING THE MODEL

Refactor the code to allow the number of lanes to be a user option.

## NETLOGO FEATURES

Note the "car-east" and "car-west" referenced in the code that were easily created with the built in Turtle Shapes Editor.

## RELATED MODELS

"Traffic Basic", "Traffic Grid", "Traffic 2 Lanes"

## CREDITS AND REFERENCES

Created for Graduate Project at Southern Illinois University, Carbondale IL.
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

car side
false
0
Polygon -7500403 true true 281 147 289 125 284 105 237 105 201 79 145 79 120 105 57 111 34 129 47 149
Circle -16777216 true false 215 123 42
Circle -16777216 true false 64 124 42
Polygon -16777216 true false 199 87 227 108 129 108 149 87
Line -8630108 false 179 82 180 108
Polygon -1 true false 58 121 52 128 34 129 53 115
Rectangle -16777216 true false 272 131 288 143

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

car-east
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car-left
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

car-right
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car-top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

car-west
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

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

van left
false
0
Polygon -7500403 true true 274 147 282 125 264 61 139 61 123 67 105 90 58 97 38 110 27 129 40 149
Circle -16777216 true false 215 123 42
Circle -16777216 true false 64 124 42
Polygon -16777216 true false 255 68 263 95 117 96 131 69
Line -7500403 true 238 65 238 103
Line -7500403 true 185 68 180 100
Polygon -1 true false 29 127 42 126 43 114 39 109
Rectangle -16777216 true false 273 131 281 142

van right
false
0
Polygon -7500403 true true 26 147 18 125 36 61 161 61 177 67 195 90 242 97 262 110 273 129 260 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 45 68 37 95 183 96 169 69
Line -7500403 true 62 65 62 103
Line -7500403 true 115 68 120 100
Polygon -1 true false 271 127 258 126 257 114 261 109
Rectangle -16777216 true false 19 131 27 142

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
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
