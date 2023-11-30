minimize
obj: 
subject to
c1: 1 resource_volume_0,silo1_ = 900
c2: 1 resource_volume_0,silo3_ = 300
c3: 1 resource_volume_0,silo2_ = 200
c4: 1 resource_volume_0,cleaner1_ = 1
c5: 5 machine1_1_ + 5 machine1_2_ - 1 resource_volume_0,silo1_ + 1 resource_volume_1,silo1_ = 0
c6: -20 machine2_1_ - 20 machine2_2_ - 1 resource_volume_0,silo3_ + 1 resource_volume_1,silo3_ = 0
c7: 10 machine2_1_ - 10 machine1_1_ + 10 machine2_2_ - 10 machine1_2_ - 1 resource_volume_0,silo2_ + 1 resource_volume_1,silo2_ = 0
c8: 1 resource_volume_1,cleaner1_ = 1
c9: 5 machine1_1_ + 5 machine1_2_ - 1 resource_volume_1,silo1_ + 1 resource_volume_2,silo1_ = 0
c10: -20 machine2_1_ - 20 machine2_2_ - 1 resource_volume_1,silo3_ + 1 resource_volume_2,silo3_ = 0
c11: 10 machine2_1_ - 10 machine1_1_ + 10 machine2_2_ - 10 machine1_2_ - 1 resource_volume_1,silo2_ + 1 resource_volume_2,silo2_ = 0
c12: 1 resource_volume_2,cleaner1_ = 1
c13: 5 machine1_1_ + 5 machine1_2_ - 1 resource_volume_2,silo1_ + 1 resource_volume_3,silo1_ = 0
c14: -20 machine2_1_ - 20 machine2_2_ - 1 resource_volume_2,silo3_ + 1 resource_volume_3,silo3_ = 0
c15: 10 machine2_1_ - 10 machine1_1_ + 10 machine2_2_ - 10 machine1_2_ - 1 resource_volume_2,silo2_ + 1 resource_volume_3,silo2_ = 0
c16: 1 resource_volume_3,cleaner1_ = 1
c17: 5 machine1_1_ + 5 machine1_2_ - 1 resource_volume_3,silo1_ + 1 resource_volume_4,silo1_ = 0
c18: -20 machine2_1_ - 20 machine2_2_ - 1 resource_volume_3,silo3_ + 1 resource_volume_4,silo3_ = 0
c19: 10 machine2_1_ - 10 machine1_1_ + 10 machine2_2_ - 10 machine1_2_ - 1 resource_volume_3,silo2_ + 1 resource_volume_4,silo2_ = 0
c20: 1 resource_volume_4,cleaner1_ = 1
c21: 5 machine1_1_ + 5 machine1_2_ - 1 resource_volume_4,silo1_ + 1 resource_volume_5,silo1_ = 0
c22: -20 machine2_1_ - 20 machine2_2_ - 1 resource_volume_4,silo3_ + 1 resource_volume_5,silo3_ = 0
c23: 10 machine2_1_ - 10 machine1_1_ + 10 machine2_2_ - 10 machine1_2_ - 1 resource_volume_4,silo2_ + 1 resource_volume_5,silo2_ = 0
c24: 1 resource_volume_5,cleaner1_ = 1
c25: 1 machine2_1_ + 1 machine2_2_ = 1
c26: 1 machine2_2_ = 1
c27: 1 machine1_1_ + 1 machine1_2_ = 1
c28: 1 machine1_2_ = 1
Bounds
resource_volume_0,silo1_ free
resource_volume_1,silo1_ free
resource_volume_2,silo1_ free
resource_volume_3,silo1_ free
resource_volume_4,silo1_ free
resource_volume_5,silo1_ free
resource_volume_0,silo3_ free
resource_volume_1,silo3_ free
resource_volume_2,silo3_ free
resource_volume_3,silo3_ free
resource_volume_4,silo3_ free
resource_volume_5,silo3_ free
resource_volume_0,silo2_ free
resource_volume_1,silo2_ free
resource_volume_2,silo2_ free
resource_volume_3,silo2_ free
resource_volume_4,silo2_ free
resource_volume_5,silo2_ free
resource_volume_0,cleaner1_ free
resource_volume_1,cleaner1_ free
resource_volume_2,cleaner1_ free
resource_volume_3,cleaner1_ free
resource_volume_4,cleaner1_ free
resource_volume_5,cleaner1_ free
Binary
machine2_1_
machine1_1_
machine2_2_
machine1_2_
End
