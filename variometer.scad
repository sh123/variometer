use <dotSCAD/src/sphere_spiral_extrude.scad>
use <dotSCAD/src/shape_circle.scad>

/* [Rendering Parameters] */
//$fa = 6.0;
//$fs = 1.0;

// number of fragments
$fn = 30;

/* [Main Parameters] */

// object to render
render_object_ = "rotor";    // ["rotor", "stator_upper", "stator_lower", "demo"]

// winding wire diameter
winding_wire_diameter_mm_ = 0.7;

// distance between wires
winding_wire_distance_mm_ = 1.0;

// number of winding wire turns on stator
stator_winding_wire_turns_ = 25;

// number of winding wire turns on rotor
rotor_winding_wire_turns_ = 30;

// distance between stator and rotor
stator_rotor_distance_mm_ = 2.0;

// rotor/stator shell width
stator_rotor_shell_width_mm_ = 1.0;

// percentage of wiring over the sphere
wiring_percentage_ = 50;
assert((wiring_percentage_ <= 100.0) && (wiring_percentage_ >= 10.0), "Wiring percentage should befrom 10 to 100");

/* [Extended Parameters] */

// material permeability
material_permeability_ = 1.0;

// diameter averaging when approximating by cylinder
diameter_to_inductance_coeff_ = 0.6;

/* [Rotor Stator Connectivty Parameters] */

// shaft cylinder or shaft hole diameter
shaft_diameter_mm_ = 5.0;

// generate shaft hole instead of shaft cylinders
shaft_use_hole_ = false;  // [true, false]

// shaft length from the rotor surface
shaft_length_mm_ = 10.0;

// how many turns to skip for shaft system
shaft_gap_turns_ = ceil(shaft_diameter_mm_ / (winding_wire_diameter_mm_ + winding_wire_distance_mm_));

// vacuum permeability
vacuum_permeability_ = 4.0 * PI * 10e-8;

// calculate rotor and stator required diameter
rotor_len_mm_ = 2 * (rotor_winding_wire_turns_ + shaft_gap_turns_) * (winding_wire_diameter_mm_ + winding_wire_distance_mm_) / PI;
rotor_diameter_mm_ = rotor_len_mm_ + rotor_len_mm_ * ((100.0 - wiring_percentage_) / 100.0);
stator_diameter_mm_ = 2 * stator_rotor_shell_width_mm_ + 2 * stator_rotor_distance_mm_ + rotor_diameter_mm_;
stator_len_mm_ = stator_diameter_mm_ * (wiring_percentage_ / 100.0);

// calculate rotor and stator inductance
rotor_inductance_h_ = inductance(material_permeability_, rotor_winding_wire_turns_, rotor_diameter_mm_ * diameter_to_inductance_coeff_, rotor_len_mm_);
stator_inductance_h_ = inductance(material_permeability_, stator_winding_wire_turns_, stator_diameter_mm_ * diameter_to_inductance_coeff_, stator_len_mm_);
maximum_inductance_h_ = rotor_inductance_h_ + stator_inductance_h_;

// print calculated parameters
echo("object to render", render_object_);
echo("rotor turns: ", rotor_winding_wire_turns_);
echo("stator turns: ", stator_winding_wire_turns_);
echo("rotor diameter: ", rotor_diameter_mm_, "mm");
echo("stator diameter: ", stator_diameter_mm_, "mm");
echo("rotor length ", rotor_len_mm_, "mm");
echo("stator length ", stator_len_mm_, "mm");
echo("rotor inductance: ", h2uh(rotor_inductance_h_), "uH");
echo("stator inductance: ", h2uh(stator_inductance_h_), "uH");
echo("maximum inductance: ~", h2uh(maximum_inductance_h_), "uH");
inductance_diff_uh_ = h2uh(stator_inductance_h_ - rotor_inductance_h_);
echo("inductance diff (stator - rotor): ", inductance_diff_uh_, "uH");
if (abs(inductance_diff_uh_) > 2.0) {
    if (inductance_diff_uh_ < 0.0) {
        echo("Increase stator turns");
    } else {
        echo("Decrease stator turns");
    }
}
echo("shaft diameter: ", shaft_diameter_mm_, "mm");
echo("shaft gap turns: ", shaft_gap_turns_);

if (render_object_ == "rotor") {
    render_rotor();
} else if (render_object_ == "demo") {
    union() {
        render_rotor();
        translate([0, 0, 20])
            render_stator("stator_upper");
        translate([0, 0, -20])
            render_stator("stator_lower");
    }
} else if (render_object_ == "stator_upper" || render_object == "stator_lower") {
    render_stator(render_object_);
} else {
    assert(false, "Unknown object to render");
}

// need to have free space in between
assert(stator_rotor_distance_mm_ > (winding_wire_diameter_mm_ / 1.5), "Stator-rotor distance is too small");

// convert millimeters to meters
function mm2m(mm) = mm / 1000.0;

// calculate area from radius
function r2area(r) = PI * (r ^ 2);

// convert diameter to radius
function d2r(d) = d / 2.0;

// calculate inductance
function inductance(mu, turns, d_mm, length_mm) = mu * vacuum_permeability_ * (turns ^ 2) * r2area(d2r(mm2m(d_mm))) / mm2m(length_mm);

// convert henries to micro henries
function h2uh(h) = h * 1e6;

// draw rotor part
module render_rotor() 
{
    // build circles
    points_circles = shape_circle(d2r(winding_wire_diameter_mm_));
    
    // additional virtual turns based on wiring percentage
    add_turns = rotor_winding_wire_turns_ * (100 - wiring_percentage_) / wiring_percentage_;
    echo("rotor adding virtual turns", add_turns);
    rotor_cap_len_mm = 0.66 * add_turns * (winding_wire_diameter_mm_ + winding_wire_distance_mm_) / PI;
    echo("rotor cap len", rotor_cap_len_mm, "mm");
    
    difference() {
        
        // draw sphere with shafts
        union() {
            sphere(d = rotor_diameter_mm_);
            if (!shaft_use_hole_) {
                rotate([0, 90, 0])
                    cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = shaft_diameter_mm_);
                rotate([0, -90, 0])
                    cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = shaft_diameter_mm_);
            }
        }
        
        if (shaft_use_hole_) {
            rotate([0, 90, 0])
                cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = shaft_diameter_mm_);
            rotate([0, -90, 0])
                cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = shaft_diameter_mm_);
        }
        // create holes inside the shaft for wire
        rotate([0, 90, 0])
            cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = 1.5 * winding_wire_diameter_mm_);
        rotate([0, -90, 0])
            cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = 1.5 * winding_wire_diameter_mm_);
        
        // remove inner sphere to build shell
        sphere(d = rotor_diameter_mm_ - 2 * stator_rotor_shell_width_mm_);
        
        // extrude lower spiral
        sphere_spiral_extrude(
            shape_pts = points_circles,
            radius = d2r(rotor_diameter_mm_),
            za_step = 10.0,
            z_circles = 4 * (rotor_winding_wire_turns_ + add_turns),
            begin_angle = 360 * ((add_turns - shaft_gap_turns_)/ 2.0),
            end_angle = 360 * ((rotor_winding_wire_turns_ + add_turns + shaft_gap_turns_) / 2.0),
            vt_dir = "SPI_UP",
            scale = 1.0
        );
        
        // extrude upper spiral
        sphere_spiral_extrude(
            shape_pts = points_circles,
            radius = d2r(rotor_diameter_mm_),
            za_step = 10.0,
            z_circles = 4 * (rotor_winding_wire_turns_ + add_turns),
            begin_angle = 360 * ((rotor_winding_wire_turns_ + add_turns + shaft_gap_turns_) / 2.0),
            end_angle = 360 * ((add_turns - shaft_gap_turns_) / 2.0),
            vt_dir = "SPI_UP",
            scale = 1.0
        );
        
        // cut upper hat
        translate([-rotor_diameter_mm_ / 2.0, -rotor_diameter_mm_ / 2.0, (rotor_diameter_mm_ - rotor_cap_len_mm) / 2.0])
            cube([rotor_diameter_mm_, rotor_diameter_mm_, rotor_cap_len_mm]);
        
        // cut lower hat
        translate([-rotor_diameter_mm_ / 2.0, -rotor_diameter_mm_ / 2.0, -(rotor_diameter_mm_ - rotor_cap_len_mm) / 2.0 - rotor_cap_len_mm])
            cube([rotor_diameter_mm_, rotor_diameter_mm_, rotor_cap_len_mm]);
        
    } // difference
}

// render upper or lower part of the stator
module render_stator(render_object) 
{
    // build circles
    points_circles = shape_circle(d2r(winding_wire_diameter_mm_));
    
    // additional virtual turns based on wiring percentage
    add_turns = stator_winding_wire_turns_ * (100 - wiring_percentage_) / wiring_percentage_;
    echo("stator adding virtual turns", add_turns);
    stator_cap_len_mm = 0.66 * add_turns * (winding_wire_diameter_mm_ + winding_wire_distance_mm_) / PI;
    echo("stator cap len", stator_cap_len_mm, "mm");
    
    difference() {
        
        // main sphere
        sphere(d = stator_diameter_mm_);
        
        // holes for shaft
        rotate([0, 90, 0])
            cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = shaft_diameter_mm_);
        rotate([0, -90, 0])
            cylinder(h = shaft_length_mm_ + rotor_diameter_mm_ / 2.0, d = shaft_diameter_mm_);
        
        // remove inner sphere to build shell
        sphere(d = stator_diameter_mm_ - 2 * stator_rotor_shell_width_mm_);
        
        // extrude lower spiral
        sphere_spiral_extrude(
            shape_pts = points_circles,
            radius = d2r(stator_diameter_mm_),
            za_step = 10.0,
            z_circles = 4 * (stator_winding_wire_turns_ + add_turns),
            begin_angle = 360 * ((add_turns - shaft_gap_turns_)/ 2.0),
            end_angle = 360 * ((stator_winding_wire_turns_ + add_turns + shaft_gap_turns_) / 2.0),
            vt_dir = "SPI_UP",
            scale = 1.0
        );
        
        // extrude upper spiral
        sphere_spiral_extrude(
            shape_pts = points_circles,
            radius = d2r(stator_diameter_mm_),
            za_step = 10.0,
            z_circles = 4 * (stator_winding_wire_turns_ + add_turns),
            begin_angle = 360 * ((stator_winding_wire_turns_ + add_turns + shaft_gap_turns_) / 2.0),
            end_angle = 360 * ((add_turns - shaft_gap_turns_) / 2.0),
            vt_dir = "SPI_UP",
            scale = 1.0
        );
        
        // cut upper hat
        if (render_object == "stator_lower")
            translate([-stator_diameter_mm_ / 2.0, -stator_diameter_mm_ / 2.0, 0])
                cube([stator_diameter_mm_, stator_diameter_mm_, stator_diameter_mm_ / 2.0]);
        else
            translate([-stator_diameter_mm_ / 2.0, -stator_diameter_mm_ / 2.0, (stator_diameter_mm_ - stator_cap_len_mm) / 2.0])
                cube([stator_diameter_mm_, stator_diameter_mm_, stator_cap_len_mm]);
        
        // cut lower hat
        if (render_object == "stator_upper")
            translate([-stator_diameter_mm_ / 2.0, -stator_diameter_mm_ / 2.0, -stator_diameter_mm_ / 2.0])
                cube([stator_diameter_mm_, stator_diameter_mm_, stator_diameter_mm_ / 2.0]);
        else
            translate([-stator_diameter_mm_ / 2.0, -stator_diameter_mm_ / 2.0, -(stator_diameter_mm_ - stator_cap_len_mm) / 2.0 - stator_cap_len_mm])
                cube([stator_diameter_mm_, stator_diameter_mm_, stator_cap_len_mm]);

    } // difference
}