output("Fine stability control disabled").
ship:partstagged("gyro")[0]:getmodule("ModuleReactionWheel"):setfield("reaction wheel authority", 0).
sas off.