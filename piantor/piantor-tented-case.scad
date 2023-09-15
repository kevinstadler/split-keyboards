pcbwidth = 138.9;
// original switchplate stl is 89.91 tall, so pretty much identical to pcb size
// original case is 144.82x95.93x8.6, with 2mm wall thickness
// bottom to start of curve is 6.6mm, so 8mm radius
pcbheight = 90.014;
centeroffset = [-pcbwidth/2, pcbheight/2, 0];
wallthickness = 2; // also used as minkowski radius
sidegap = .5;
// 2mm switchplate, 1.8mm pcb, 1.7mm space for hotswap sockets -> 5.5mm total
// screwhole cylinders should poke out the full 1.7mm so that 5mm screws can still dig in 1.2mm
verticalgap = 5.5;
innerheight = verticalgap - wallthickness;
legposition = [17, -72, 0];
legdistance = 54;

module outline(height, offsetradius=0) {
    linear_extrude(height=height) {
        offset(r=offsetradius) {
            fill() {
                import("pcb outline.svg");
            }
        }
    }
}

// 1st print
//angle = 30;
//anglecenter = [pcbwidth, -44, verticalgap/2];
angle = 40;
anglecenter = [pcbwidth, -44, verticalgap/2];
module angledbit(thickness, zoffset=0) {
    translate(anglecenter) rotate([0, 180-angle, 0]) translate([0, 0, thickness/2-zoffset]) cube([30, 56, thickness], center=true);
}

module angledoutline(height, offsetradius=0) {
    difference() {
        outline(height, offsetradius);
        angledbit(10, offsetradius);
    }
}

module legbase(radius=5, height=30, distance=54, basethickness=2) {
    cylinder(height, r=radius);
    translate([0, distance, 0]) cylinder(height, r=radius);
    translate([-radius, 0, 0]) cube([2*radius, distance, basethickness]);
}

module legs(radius=5, height=25, distance=54, basethickness=2) {
    difference() {
        legbase(radius, height, distance, basethickness);
        // 8x10 magnets -- take out 8.1mm (too small)
        translate([0, 0, -1]) cylinder(11.5, r=4.1);
        translate([0, distance, -1]) cylinder(11.5, r=4.1);
        // M8 screw 3.5, M6 2.5
        translate([0, 0, 10]) cylinder(height, r=2.5);
        translate([0, distance, 10]) cylinder(height, r=2.5);
    }
}

translate(legposition) translate([-30, 0, 0]) legs();

difference() {
    union() {
        minkowski() {
            angledoutline(innerheight, sidegap);
            sphere(r=wallthickness, $fn=10);
        }
    }
    // inner hole -- no need for z-offset because minkowski extended the model into -z
    angledoutline(20, sidegap);

    // angled stopper indents: 8, 10 or 12mm
    for (y = [-22, 23]) {
        translate(anglecenter) rotate([0, 180-angle, 0]) translate([2.5, y, 1.2]) cylinder(5, r=4.2);
    }
    // or use rubber strip instead?
    striplength = 46;
    translate(anglecenter) rotate([0, 180-angle, 0]) translate([2.5, -striplength/2, .3]) legbase(distance=striplength, radius=3, basethickness=5);
    
    // USB
    translate([7, -7-wallthickness, verticalgap-2]) cube([10, 3*wallthickness, verticalgap]);

    // TRRS cable
    translate([-3*wallthickness, -65.18, verticalgap+1]) 
    rotate([0, 90, 0]) cylinder(10, r=3);

    // bottom magnet indents: 3mm tall magnets fit into the 1.7mm gap + 1.4mm into the (total 2mm thick) floor. (the remaining .6mm get another .2mm scraped off by the indent from below)
    // legs
    translate(legposition) {
        translate([0, 0, -1.4]) cylinder(100, r=5.2);
        translate([0, legdistance, -1.4]) cylinder(100, r=5.2);
    }
    // just case
    translate([100, -23, -1.4]) cylinder(100, r=5.2);
    translate([100, -63, -1.4]) cylinder(100, r=5.2);

    // bottom indent for legs: .2mm, also make it a bit wider
    translate(legposition) translate([0, 0, -wallthickness]) legbase(5.25, height=.2, basethickness=.2);
    
    // 8mm radius indents for non-leg-use rubber feet
    // inner top
    translate([10, -11, -wallthickness]) cylinder(1, r=4.1);
    translate([4, -16, -wallthickness]) cylinder(1, r=4.1);
    // inner bottom
    translate([20.7, -83.5, -wallthickness]) cylinder(1, r=4.1);
    translate([13, -83.5, -wallthickness]) cylinder(1, r=4.1);
    // outer top
    translate([123, -20.5, -wallthickness]) cylinder(1, r=4.1);
    translate([128.5, -26, -wallthickness]) cylinder(1, r=4.1);
    // outer bottom
    translate([123, -66.5, -wallthickness]) cylinder(1, r=4.1);
    translate([128.5, -61, -wallthickness]) cylinder(1, r=4.1);
    // top
    translate([71, -4, -wallthickness]) cylinder(1, r=4.1);
    translate([79, -4, -wallthickness]) cylinder(1, r=4.1);
}

$fn = 20;
module m2screwhole(x, y) {
    translate([x, y, 0])
    difference() {
        cylinder(1.7, r=2, true);
        translate([0, 0, .1]) cylinder(1.7, r=.8, true);
    }
}

m2screwhole(28.35, -23.65);
m2screwhole(26.05, -64.25);
m2screwhole(83.45, -17.65);
m2screwhole(119.85, -35.15);
m2screwhole(119.85, -52.15);
