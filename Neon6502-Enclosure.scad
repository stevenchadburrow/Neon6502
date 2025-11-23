// Neon6502

module radiusedblock(xlen,ylen,zlen,radius) {
	hull() {
		translate([radius,radius,radius]) sphere(r=radius);
		translate([xlen + radius , radius , radius]) sphere(r=radius);
		translate([radius , ylen + radius , radius]) sphere(r=radius);    
		translate([xlen + radius , ylen + radius , radius]) sphere(r=radius);
		translate([radius , radius , zlen + radius]) sphere(r=radius);
		translate([xlen + radius , radius , zlen + radius]) sphere(r=radius);
		translate([radius,ylen + radius,zlen + radius]) sphere(r=radius);
		translate([xlen + radius,ylen + radius,zlen + radius]) sphere(r=radius);
	}
}

$fn = 20; // higher detail to curves


scale([1,-1,1])
{
	difference()
	{
		// outside
		translate([-5,-5,-5])
		{
			radiusedblock(100,100,20,5);
		}
		
		// inside
		translate([-1,-1,0])
		{
			cube([102,102,20]);
		}
			
		// vga
		translate([9,-10,5])
		{
			cube([33,20,14]);
		}
			
		// usb
		translate([45,-10,5])
		{
			cube([17.5,20,12]);
		}
		
		// switch
		translate([67,-10,7])
		{
			cube([11,20,7]);
		}
		
		// reset
		translate([85.75,-10,4])
		{
			rotate([-90,0,0])
			{
				cylinder(20,2.5,2.5);
			}
		}
		
		// led
		translate([86.25,15.0,10])
		{
			cylinder(20,2.5,2.5);
		}
		
		// buttons
		translate([14.25,24.75,10])
		{
			cylinder(20,4,4);
		}
		translate([14.25,40.25,10])
		{
			cylinder(20,4,4);
		}
		translate([6.5,32.5,10])
		{
			cylinder(20,4,4);
		}
		translate([22.0,32.5,10])
		{
			cylinder(20,4,4);
		}
		
		translate([86.25,24.75,10])
		{
			cylinder(20,4,4);
		}
		translate([86.25,40.25,10])
		{
			cylinder(20,4,4);
		}
		translate([78.5,32.5,10])
		{
			cylinder(20,4,4);
		}
		translate([94.0,32.5,10])
		{
			cylinder(20,4,4);
		}
		
		// screw holes
		translate([4.75,4.75,5])
		{
			rotate([180,0,0])
			{
				cylinder(20,2.5,2.5);
			}
		}
		translate([95.25,4.75,5])
		{
			rotate([180,0,0])
			{
				cylinder(20,2.5,2.5);
			}
		}
		translate([4.75,95.25,5])
		{
			rotate([180,0,0])
			{
				cylinder(20,2.5,2.5);
			}
		}
		translate([95.25,95.25,5])
		{
			rotate([180,0,0])
			{
				cylinder(20,2.5,2.5);
			}
		}
		
		// comment out for top only
		translate([-10,-10,-10])
		{
			//cube([120,120,10+5]);
		}
		
		// comment out for bottom only
		translate([-10,-10,5])
		{
			//cube([120,120,30]);
		}
	}
	
	difference()
	{
		union()
		{
			// screw supports
			translate([4.75,4.75,0])
			{
				difference()
				{
					cylinder(20,4.5,4.5);
					cylinder(20,1.0,1.0);
				}
			}
			translate([95.25,4.75,0])
			{
				difference()
				{
					cylinder(20,4.5,4.5);
					cylinder(20,1.0,1.0);
				}
			}
			translate([4.75,95.25,0])
			{
				difference()
				{
					cylinder(20,4.5,4.5);
					cylinder(20,1.0,1.0);
				}
			}
			translate([95.25,95.25,0])
			{
				difference()
				{
					cylinder(20,4.5,4.5);
					cylinder(20,1.0,1.0);
				}
			}
			
			// support supports
			translate([1,1,0])
			{
				cylinder(20,3,3);
			}
			translate([99,1,0])
			{
				cylinder(20,3,3);
			}
			translate([1,99,0])
			{
				cylinder(20,3,3);
			}
			translate([99,99,0])
			{
				cylinder(20,3,3);
			}
			
			// button supports
			translate([14.25,24.75,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
			translate([14.25,40.25,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
			translate([6.5,32.5,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
			translate([22.0,32.5,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
		
			translate([86.25,24.75,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
			translate([86.25,40.25,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
			translate([78.5,32.5,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
			translate([94.0,32.5,15])
			{
				difference()
				{
					cylinder(5,6,6);
					cylinder(5,4,4);
				}
			}
		}
		
		// pcb
		translate([-10,-10,5-1.6])
		{
			cube([120,120,1.6]);
		}
		
		// comment out for top only
		translate([-10,-10,-10])
		{
			//cube([120,120,10+5]);
		}
		
		// comment out for bottom only
		translate([-10,-10,5])
		{
			//cube([120,120,30]);
		}
	}
}

module button()
{
	difference()
	{
		union()
		{
			cylinder(15, 3.5, 3.5);
			cylinder(2, 5, 5);
			intersection()
			{
				sphere(17);
				cylinder(100, 3.5, 3.5);
			}
		}
		translate([-1.5, -1.5, 0])
		{
			cube([3.0, 3.0, 3.0]);
		}
	}
}


scale([1,-1,1])
{
	translate([14.25,24.75,10])
	{
		button();
	}
	translate([14.25,40.25,10])
	{
		button();
	}
	translate([6.5,32.5,10])
	{
		button();
	}
	translate([22.0,32.5,10])
	{
		button();
	}
	
	translate([86.25,24.75,10])
	{
		button();
	}
	translate([86.25,40.25,10])
	{
		button();
	}
	translate([78.5,32.5,10])
	{
		button();
	}
	translate([94.0,32.5,10])
	{
		button();
	}
}

//button();












