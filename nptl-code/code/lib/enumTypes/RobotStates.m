classdef (Enumeration) RobotStates < Simulink.IntEnumType
%    Robot states, initially cloned off of CursorStates.m    
%    I'm keeping the same enumerations as CursorStates for
%    similar states.
%    Sergey 10 February 2017
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        STATE_INIT(0)
        STATE_PRE_TRIAL(1)
        STATE_NEW_TARGET(2)
        STATE_MOVE(3)  % grasp isn't an option, move around
        STATE_ACQUIRE(4)
        STATE_SUCCESS(5)
        STATE_FAIL(6)
        STATE_CENTER_TARGET(7)
        STATE_END(8)
        STATE_RECENTER_DELAY(11)

        STATE_HOVER(13)
        STATE_MOVE_GRASP_OPEN(14) % Moving and commanding an open grasper
        STATE_MOVE_GRASP_CLOSED(15) % Moving and commanding a closed grasper
      
        SOUND_STATE_IDLE(0)
        SOUND_STATE_SUCCESS(1)
        SOUND_STATE_FAIL(2)
        SOUND_STATE_GO(3)
        SOUND_STATE_OVER_TARGET(4)
    end
    methods (Static = true)
        function retVal = addClassNameToEnumNames()
            retVal = true;
        end
    end
end