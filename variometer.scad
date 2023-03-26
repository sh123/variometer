/* [Main Parameters] */

// winding wire diameter
winding_wire_diameter_mm_ = 1.0;

// distance between wires as a factor of winding wire diameter
winding_wire_distance_mm_ = 0.5;

// number of winding wire turns on stator
stator_winding_wire_turns_ = 28;

// number of winding wire turns on rotor
rotor_winding_wire_turns_ = 30;

// distance between stator and rotor
stator_rotor_distance_mm_ = 2.0;

// rotor/stator shell width
stator_rotor_shell_width_mm_ = 1.0;

// percentage of wiring
wiring_percentage_ = 80;
assert((wiring_percentage_ <= 100.0) && (wiring_percentage_ >= 50.0), "Wiring percentage should befrom 50 to 100");

// material permeability
material_permeability_ = 1.0;

// vacuum permeability
vacuum_permeability_ = 4.0 * PI * 10e-8;

// calculate rotor and stator required diameter
rotor_len_mm_ = rotor_winding_wire_turns_ * (winding_wire_diameter_mm_ + winding_wire_distance_mm_);
rotor_diameter_mm_ = rotor_len_mm_ + rotor_len_mm_ * ((100.0 - wiring_percentage_) / 100.0);
stator_diameter_mm_ = 2 * stator_rotor_shell_width_mm_ + 2 * stator_rotor_distance_mm_ + rotor_diameter_mm_;
stator_len_mm_ = stator_diameter_mm_ * (wiring_percentage_ / 100.0);

// calculate rotor and stator inductance
rotor_inductance_h_ = inductance(material_permeability_, rotor_winding_wire_turns_, rotor_diameter_mm_ * 0.66, rotor_len_mm_);
stator_inductance_h_ = inductance(material_permeability_, stator_winding_wire_turns_, stator_diameter_mm_ * 0.66, stator_len_mm_);
maximum_inductance_h_ = rotor_inductance_h_ + stator_inductance_h_;

// print calculated parameters
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

render_rotor();

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

module render_rotor() 
{
    sphere(d = rotor_diameter_mm_);
}