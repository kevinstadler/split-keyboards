$fn = 12;

pcbwidth = 138.9;
// original switchplate stl is 89.91 tall, so pretty much identical to pcb size
// original case is 144.82x95.93x8.6, with 2mm wall thickness
// bottom to start of curve is 6.6mm, so 8mm radius
pcbheight = 90.014;
centeroffset = [-pcbwidth/2, pcbheight/2, 0];
wallthickness = 2; // also used as minkowski radius
sidegap = .55; // .5 in original print quite tight
// 2mm switchplate, 1.8mm pcb, 1.7mm space for hotswap sockets -> 5.5mm total
// screwhole cylinders should poke out the full 1.7mm so that 5mm screws can still dig in 1.2mm
verticalgap = 5.6;
innerheight = verticalgap - wallthickness;
legposition = [17.5, -65, 0]; // -72 collides with hotswap, go -66
legdistance = 47;

module outline(height, offsetradius=0) {
    linear_extrude(height=height) {
        offset(r=offsetradius) {
            fill() {
                translate([0, -90, 0]) import("right-outline.svg");
            }
        }
    }
}

module screwholes (height, diameter=4.4) {
    linear_extrude(height=height) {
        offset(r=(diameter-4.4)/2) {
            fill() {
                translate([0, -90, 0]) import("right-screwholes.svg");
            }
        }
    }
}

screwholes = [[28.35, -23.65],
    [26.05, -64.25],
    [83.45, -17.65],
    [99.65, -64.25],
    [119.85, -35.15],
    [119.85, -52.15]];

// 1st print
//angle = 30;
//anglecenter = [pcbwidth, -44, verticalgap/2];
angle = 40;
anglecenter = [pcbwidth+sidegap, -44, verticalgap/2];
module angledbit(thickness, zoffset=0) {
    translate(anglecenter) rotate([0, 180-angle, 0]) translate([0, 0, thickness/2-zoffset]) cube([30, 56, thickness], center=true);
}

module angledoutline(height, offsetradius=0) {
    difference() {
        outline(height, offsetradius);
        angledbit(10, offsetradius);
    }
}

module legbase(radius, height=.28*70, distance=legdistance, basethickness=.28*11) {
    cylinder(height, r=radius);
    translate([0, distance, 0]) cylinder(height, r=radius);
    translate([-radius, 0, 0]) cube([2*radius, distance, basethickness]);
}

module legs(radius, height=.28*70, distance=legdistance, basethickness=.28*11) {
    difference() {
        union() {
            // a *nice*, rounded legbase
            baseradius = 1;
            minkowski() {
                legbase(radius-baseradius, height, distance, basethickness-baseradius);
                difference() {
                    sphere(baseradius);
                    translate([-baseradius, -baseradius, -baseradius]) cube([2*baseradius, 2*baseradius, baseradius]);
                }
            }
            // and some extra joint support
            difference() {
                union() {
                    translate([0, 9.5, 0]) rotate([45, 0, 0]) cylinder(10, r=radius/2);
                    translate([0, distance-9.5, 0]) rotate([-45, 0, 0]) cylinder(10, r=radius/2);
                }
                translate([0, 0, -10]) cube([2*radius, 2*distance+radius, 20], center=true);
            }
        }
        for (y = [0, distance]) {
            // 8x10 magnets -- 8.2 doesn't fit, 8.8 tiny bit too lose (once in)
            translate([0, y, -1]) cylinder(11.6, r=4.35);
            // M8 screw r=3.5, M6 r=2.5 -- should be 5mm but came out 4.4!
            translate([0, y, 10]) cylinder(height, r=3.1); // 3 still tight
        }
    }
}

module bottom(left = true, legradius=6) {
    difference() {
        union() {
            minkowski() {
                angledoutline(innerheight, sidegap);
                sphere(r=wallthickness, $fn=10); // save on that minkowski..
            }
        }
        // hard board and hotswap socket cutout
        translate([0, 0, 1.7]) outline(verticalgap, sidegap);
        for (i = [0:2]) {
            translate([pcbwidth-8.5, (left ? -30 : -23) -i*17, wallthickness]) cube([16, 7, 2*wallthickness], center=true);
        }

        // inner hole -- z-offset is 0 because minkowski extended the bottom plate into -z
        angledoutline(20, sidegap);

        // angled stopper indents: 8, 10 or 12mm
    //    for (y = [-22, 23]) {
    //        translate(anglecenter) rotate([0, 180-angle, 0]) translate([2.5, y, 1]) cylinder(5, r=4.2);
    //    }
        // or use rubber strip instead?
        striplength = 46;
//        translate(anglecenter) rotate([0, 180-angle, 0]) translate([2, -striplength/2, 1]) legbase(distance=striplength, radius=3.5, basethickness=5);
        
        if (left) {
            // USB
            translate([11.5, -7+wallthickness+sidegap+.1, verticalgap-.5]) {
                // jack cutout
                cube([8, 2*wallthickness, 3], center=true);
                // decorative plug cutout (half of wall)
                minkowski() {
                    usbradius = 2.5;
                    cube([12-2*usbradius, wallthickness, 4-usbradius], center=true);
                    difference() {
                        sphere(usbradius);
                        translate([-usbradius, -usbradius, -usbradius]) cube([2*usbradius, usbradius, 2*usbradius]);
                    }
                }
            }
        }

        // TRRS cable
        translate([-wallthickness-sidegap-.2, -65.75, verticalgap+.5]) rotate([0, 90, 0]) {
            //  5.5 for the plug
            cylinder(2*wallthickness, r=2.75);
            // 9 for the cable
            cylinder(wallthickness/2, r=4);
        }

        // inside magnet indents: 3mm tall magnets fit into the 1.7mm gap + 1.4mm into the (total 2mm thick) floor.
        // 5.2 radius still a bit too smol, try 5.3
        translate([96, -18, -1.4]) cylinder(100, r=5.3);
        translate([96, -56, -1.4]) cylinder(100, r=5.3);

        // the bridge indents come out as 1.6mm
        bridgesag = .6;
        // for the leg side, the remaining .6mm get another .2mm scraped off by the indent from below)
        translate(legposition) {
            translate([0, 0, -1.4+bridgesag]) cylinder(100, r=5.3);
            translate([0, legdistance, -1.4+bridgesag]) cylinder(100, r=5.3);
        }
        // bottom indent for legs: .4mm (two layers), also make it a bit wider
        translate(legposition) translate([0, 0, -wallthickness]) legbase(legradius+0.25, height=.4+bridgesag, basethickness=.4+bridgesag);

        
        // 8mm radius indents for non-leg-use rubber feet -- 4.2 too smol
        rindent = 1.4;
        rradius = 4.5;
        // inner top 
        translate([10, -11, -wallthickness]) cylinder(rindent, r=rradius);
        translate([4, -16, -wallthickness]) cylinder(rindent, r=rradius);
        // inner bottom
        translate([20.7, -83.5, -wallthickness]) cylinder(rindent, r=rradius);
        translate([13, -83.5, -wallthickness]) cylinder(rindent, r=rradius);
        // outer top
        translate([124, -21.5, -wallthickness]) cylinder(rindent, r=rradius);
        translate([129.5, -27, -wallthickness]) cylinder(rindent, r=rradius);
        // outer bottom
        translate([123, -65.5, -wallthickness]) cylinder(rindent, r=rradius);
        translate([128.5, -60, -wallthickness]) cylinder(rindent, r=rradius);
        // top
        translate([71, -4, -wallthickness]) cylinder(rindent, r=rradius);
        translate([79, -4, -wallthickness]) cylinder(rindent, r=rradius);
  }

    // little support corner underneath the pico
    translate([1.5, -9, 0]) cylinder(1.6, r=1.5);
    translate([1.5, -65, 0]) cylinder(1.6, r=1.5);


/*    module m2screwhole(x, y) {
        translate([x, y, 0])
        difference() {
            cylinder(1.7, r=2, true);
//            translate([0, 0, .1]) cylinder(1.7, r=1, true);
            translate([0, 0, .1]) cylinder(1.7, r=.8, true);
        }
    }

    m2screwhole(28.35, -23.65);
    m2screwhole(26.05, -64.25);
    m2screwhole(83.45, -17.65);
    m2screwhole(99.65, -64.25);
    m2screwhole(119.85, -35.15);
    m2screwhole(119.85, -52.15);
    */
}

// 13.8mm holes for the switches on the svg, but openscad thinks it's 14.8 ok...
module switches(height, cutout=14.8) {
    linear_extrude(height=height) {
        offset(r=(cutout-14.8)/2) {
            fill() {
                translate([0, -90, 0]) import("right-switches.svg");
            }
        }
    }
}

module switchplate(left = true) {
    difference() {
        outline(2, -.1); // shave a little off..
        minkowski() {
            sphere(wallthickness);
            union() {
                // pico
                translate([0, -7-56+wallthickness, 0]) cube([25-wallthickness, 56, 3]);
                // the trrs is only 6 wide, but 3mm gap to the pico
                translate([0, -7-63+wallthickness, 0]) cube([13.5-wallthickness, 11-wallthickness, 3]);
            }
        }
        // screwholes: M2 through
        screwholes(3, 2.55);
        // 3.5mm diameter countersunk part at top
        // leave a layer for stability...
//        translate([0, 0, 1.2]) screwholes(2, 4);

        // .8mm thick lip for the 15mm outline
        
        // below that it's 2.2mm to the pcb:
        // - 1.3mm gap that's only 13.8mm
        // - .9mm with the little tab that goes 14.5mm wide
        // https://github.com/keyboardio/keyswitch_documentation/blob/master/datasheets/Kailh/CPG135001D03rev1-ChocWhite.pdf
        // https://github.com/josefadamcik/SofleKeyboard/issues/136
        
        // cut-through - on the original switchplate stl this is 14.2 and 1.2mm high), which actually came out as 13.85mm which still killed some of the tabs...
        // 14.4 (comes out as 14) is a bit too spacious, so go with 14.3
        switches(3, 14.3);
        // space for tabs -- on the original 15.8mm across and .8mm high
        switches(1, 15.8);
    }
}

module picocover(left = true) {
    // 52 is the pcb, add 3.5mm on TRRS side, 1.5 on USB
    difference() {
        minkowski() {
            translate([0, -1, (-3+wallthickness)/2]) cube([25 - 2*wallthickness, 57 - 2*wallthickness, 4.5 - wallthickness], true);
            difference() {
                sphere(wallthickness);
                translate([0, 0, wallthickness]) cube([2*wallthickness, 2*wallthickness, 2*wallthickness], center=true);
            }
        }
        for (x = [-5.7, 5.7]) {
            // magnet holes should be 48.26 apart, actually 47
            for (y = [-23.5, 23.5]) {
                // 1mm into the material
                translate([x, y, 0]) cylinder(2, r=1.25, center=true);
            }
        }
        // pcb space
        translate([0, 0, 1.5]) cube([25, 52, 3], true);
        // smd component space
        translate([0, 4.5, 0]) cube([18, 33.8, 3], true);
        // reset button space
        translate([3, 11, -1]) cube([4, 6, 3], true);
        // usb space : 8x6 which sticks out 1.3 over the 25.5 edge
        translate([0, 25.5 + 1.3 - 7/2, 0]) cube([8.5, 7, 5], true);
        // surface text
        mirror([0, 1, 0]) rotate([0, 0, left ? -90 : 90]) translate([24, -3, -3.69]) linear_extrude(height = 0.2) {
            translate([0, 0, 0]) text(text = str("the Futile"), font = "IBM Plex Sans:style=Bold", size = 5, halign="right", spacing=.9);
            translate([0, -6, 0]) text(text = str("Corporation"), font = "IBM Plex Sans:style=Bold", size = 5, halign="right", spacing=.9);        
        }
        if (left) {
            // cutoff
            translate([-20, 25.5, -20]) cube([50, 50, 50]);
        } else {
            // outer case space
        }
    }
}

picocover();
//translate([30, 0, 0]) picocover(false);

legradius = 6;
// right
//mirror([1, 0, 0]) bottom(true, legradius); //translate([0, 0, 0])
//mirror([1, 0, 0])
//switchplate();
//translate([25/2, -7-57/2+3, 0])
//rotate([0, 180, 0]) picocover(false);

// left
bottom(false, legradius);
mirror([1, 0, 0]) switchplate();
//translate([-25/2, -7-57/2+3, 0])
//rotate([0, 180, 0]) picocover();
// legs
//translate(legposition) translate([-30, 80, 0]) legs(legradius);

// tpu feet
/*for (i = [0, 1]) {
    translate([-50, 90-35*(i+1), 0]) {
        difference() {
            // screw heads are 4.6mm, add 2mm bottom and more
            cube([20, 20, 10], center=true);
            translate([0, 1, 4]) rotate([angle, 0, 0]) cylinder(16, r=5, $fn=6, center=true);
        }
    }
}
*/