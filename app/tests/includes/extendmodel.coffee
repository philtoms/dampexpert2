@extend = m1:->
  @map f2:456
  @on excmd:-> @publish expub:{f1:'ex1'}
