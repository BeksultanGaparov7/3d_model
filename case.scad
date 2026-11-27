// =====================================================================
//  Birthday OLED box : ESP32-C3 SuperMini + 2.42" SSD1309 128x64 OLED
//  + 400 mAh LiPo (502535) + TP4056/DW01 charger + 2x 6x6 buttons
//  + slide power switch.  All units mm.  Fully parametric.
//
//  Render one part:  openscad -D 'part="base"' -o base.stl case.scad
//  part = "assembly" | "base" | "lid" | "cap" | "test_fit" | <component>
// =====================================================================
part = "assembly";
$fn = 40;

// ---------- MEASURE THESE ON YOUR REAL PARTS (calipers) -------------
oled_w = 61.5;  oled_h = 39.5;  oled_t = 1.2;   // OLED PCB
hole_in = 2.0;  hole_d = 2.6;                   // OLED mount holes: centre from edge, dia
glass_w = 57.0; glass_h = 31.0; glass_t = 2.0;  // glass panel on front of PCB
aa_w = 55.01;   aa_h = 27.49;                   // visible pixel area
oled_back = 2.0;                                // tallest part on OLED back side

mcu_l = 22.52; mcu_w = 18.0; mcu_t = 1.0;       // ESP32-C3 SuperMini PCB
usb_w = 8.94;  usb_h = 3.26; usb_l = 7.35; usb_over = 0.6; // its USB-C socket

bat_l = 35; bat_w = 25; bat_t = 5.0;            // LiPo 502535 (~400 mAh)
chg_l = 28; chg_w = 17; chg_t = 1.6; chg_parts = 3.4; // TP4056+DW01 USB-C board
tape  = 0.4;                                    // foam tape battery->charger

btn = 6.0; btn_body = 3.5; btn_total = 5.0;     // 6x6x5 tactile switch
sw_l = 8.6; sw_d = 3.6; sw_h = 3.5; sw_lever = 4.0; // SS12D00G4 slide switch

// ---------- case parameters ----------
clr = 0.3; wall = 2.0; floor_t = 1.6; lid_t = 1.6; r_out = 3.0;
fit = 0.15;                       // snug fit for pockets

in_w = oled_w + 2*clr;  in_h = oled_h + 2*clr;
W = in_w + 2*wall;      H = in_h + 2*wall;

z_chg  = floor_t;                                       // charger lies in a floor pocket
z_bat  = z_chg + chg_t + chg_parts + 0.1;               // battery rests on a shelf above it
z_oled = z_bat + bat_t + tape + 0.3 + oled_back;        // OLED PCB bottom (foam pad on battery)
z_glass= z_oled + oled_t;
z_wall = z_glass + glass_t + 0.2;                       // top of base walls
Ht     = z_wall + lid_t;

cx = W/2; cy = H/2;
holes = [for (sx=[0,1], sy=[0,1])
         [wall+clr+hole_in + sx*(oled_w-2*hole_in),
          wall+clr+hole_in + sy*(oled_h-2*hole_in)]];

// SuperMini placement (USB socket faces -X wall, sits in a wall pocket)
pocket_d = 1.2;                               // wall pocket depth
mcu_x0 = wall - pocket_d;                     // PCB edge touches pocket bottom
mcu_y0 = cy - mcu_w/2;
mcu_z0 = floor_t + 1.0;                       // on 1 mm rails
usb_x0 = mcu_x0 - usb_over;
usb_zc = mcu_z0 + mcu_t + usb_h/2;
mcu_x1 = mcu_x0 + mcu_l;
stop_x0 = mcu_x1 + 0.2;  stop_t = 1.2;

// battery pocket
bat_x0 = stop_x0 + stop_t + 0.3;
bat_y1 = H - wall - btn_total - 0.9 - 1.0 - 0.3; // leave room for buttons + rib
bat_y0 = bat_y1 - bat_w;
rib_y0 = bat_y1 + 0.3;  rib_y1 = rib_y0 + 1.0;
chg_x0 = bat_x0 + (bat_l - chg_l - usb_over)/2;  chg_y0 = bat_y0 + (bat_w - chg_w)/2;

// buttons (pressed from the +Y side wall)
btn_xs = [cx - 11, cx + 11];
btn_zc = floor_t + btn/2;
btn_y0 = rib_y1;                       // body back face
cap_fl = 0.9; cap_sq = 5.2;

// slide switch (-Y side wall)
sw_xc = wall + 12.5;  sw_zc = floor_t + sw_h/2;   // under the SuperMini, left of the battery

// power-path / divider perfboard
pp = [10, 5, 3];  pp_x0 = cx - 3; pp_y0 = wall + 0.6;

// ====================================================================
module rbox(s, r) { // rounded box (xy corners)
  hull() for (x=[r, s[0]-r], y=[r, s[1]-r]) translate([x,y,0]) cylinder(r=r, h=s[2]);
}
module rrect_x(w, h, r, len) { // rounded rect hole along X, centered yz
  rotate([0,90,0]) hull() for (a=[-1,1], b=[-1,1])
    translate([a*(h/2-r), b*(w/2-r), 0]) cylinder(r=r, h=len);
}

// =========================== BASE ===================================
// snap features (flexible): reported separately by the fit checker
module snaps() {
  // SuperMini hooks over the PCB back corners
  for (y = [mcu_y0, mcu_y0+mcu_w-2.4])
    translate([stop_x0, y, mcu_z0+mcu_t+0.1])
      hull() { translate([-0.7,0,0]) cube([0.7+0.01, 2.4, 0.3]); translate([0,0,0.8]) cube([0.01,2.4,0.01]); }
  // nubs over the tactile switches
  for (x = btn_xs) for (s=[-1,1])
    translate([s<0 ? x-btn/2-fit : x+btn/2+fit-0.35, btn_y0+0.5, floor_t+btn+0.05]) cube([0.35, btn_body-1, 0.3]);
  // nubs over the slide switch
  for (s=[-1,1])
    translate([s<0 ? sw_xc-sw_l/2-fit : sw_xc+sw_l/2+fit-0.35, wall+0.6, floor_t+sw_h+0.05]) cube([0.35, sw_d-1.2, 0.3]);
  // ramp catch behind the slide switch
  translate([sw_xc-sw_l/2+0.5, wall+sw_d+fit, floor_t-0.01]) hull() { cube([sw_l-1, 0.6, 0.51]); cube([sw_l-1, 1.6, 0.01]); }
}
module base(with_snaps=true) {
  difference() {
    union() {
      difference() {
        rbox([W, H, z_wall], r_out);
        translate([wall, wall, floor_t]) rbox([in_w, in_h, z_wall], 1.0);
      }
      // screw bosses (OLED + lid share the same 4 M2 screws)
      for (p = holes) translate([p[0], p[1], 0]) cylinder(d=5.2, h=z_oled);
      // ---- SuperMini cradle ----
      for (y = [cy-5.5, cy+4.0]) translate([wall+2, y, floor_t-0.01]) cube([mcu_l-4, 1.5, 1.01]);
      for (y = [mcu_y0-fit-1.0, mcu_y0+mcu_w+fit])
        translate([wall+1, y, floor_t-0.01]) cube([mcu_l-3, 1.0, mcu_z0+mcu_t+0.8-floor_t]);
      // back stop behind the SuperMini
      difference() {
        translate([stop_x0, mcu_y0-1.2, floor_t-0.01]) cube([stop_t, mcu_w+2.4, mcu_z0+mcu_t+0.9-floor_t]);
        // chamfer so the board's back edge can swing down past it
        translate([stop_x0, cy, mcu_z0+mcu_t+0.9]) rotate([0,45,0]) cube([1.2, mcu_w+4, 1.2], center=true);
      }
      // ---- battery shelf (solid, with the charger pocket inside) + battery walls ----
      difference() {
        union() {
          translate([bat_x0-1.1, bat_y0-1.1, floor_t-0.01]) cube([bat_l+2.2, bat_w+1.4, z_bat-floor_t+0.01]);
          translate([bat_x0-1.1, bat_y0-1.1, floor_t-0.01]) difference() {
            cube([bat_l+2.2, bat_w+2.2, z_bat+3.5-floor_t]);
            translate([0.8, 0.8, 0]) cube([bat_l+0.6, bat_w+0.6, 20]);
          }
        }
        // charger pocket
        translate([chg_x0-fit, chg_y0-fit, floor_t]) cube([chg_l+usb_over+2*fit, chg_w+2*fit, 10]);
        // wire channels: charger B+/B- (left end) and IN+/IN- (right end)
        translate([bat_x0-2, chg_y0+2, floor_t+0.6]) cube([chg_x0-bat_x0+2.1, chg_w-4, 20]);
        translate([chg_x0+chg_l-1, chg_y0+4, z_chg+chg_t+usb_h+0.15]) cube([10, chg_w-8, 20]);
      }
      // top rib = battery wall + button back-stop
      translate([btn_xs[0]-4.5, rib_y0, floor_t-0.01]) cube([bat_x0+bat_l+1.1-(btn_xs[0]-4.5), 1.0, z_bat+3.5-floor_t]);
      // ---- button pockets ----
      for (x = btn_xs) for (s=[-1,1])
        translate([x + s*(btn/2+fit) + (s<0 ? -1.0 : 0), btn_y0, floor_t-0.01]) cube([1.0, H-wall-btn_y0+0.01, btn+0.35]);
      // ---- slide switch pocket ----
      for (s=[-1,1]) translate([sw_xc + s*(sw_l/2+fit) + (s<0?-1.0:0), wall-0.01, floor_t-0.01]) cube([1.0, sw_d+fit+1.0, sw_h+0.35]);
      if (with_snaps) snaps();
    }
    // pilot holes for M2 self-tapping screws
    for (p = holes) translate([p[0], p[1], z_oled-10]) cylinder(d=1.7, h=11);
    // USB wall pocket: PCB slot + socket slot (socket captured under its ceiling)
    translate([wall-pocket_d, mcu_y0-0.2, mcu_z0-0.2]) cube([pocket_d+0.01, mcu_w+0.4, mcu_t+0.4]);
    translate([wall-pocket_d, cy-usb_w/2-0.2, mcu_z0-0.2]) cube([pocket_d+0.01, usb_w+0.4, mcu_t+usb_h+0.34]);
    // USB-C plug opening (fits plugs up to ~12 x 6.5 mm)
    translate([-0.01, cy, usb_zc]) rrect_x(12.4, 6.8, 2.0, wall-pocket_d+0.02);
    // button plunger holes
    for (x = btn_xs) translate([x, H-wall-0.01, btn_zc]) rotate([-90,0,0]) cylinder(d=4.3, h=wall+0.02);
    // wire notches in rib behind buttons
    for (x = btn_xs) translate([x-1.5, rib_y0-0.1, floor_t+btn-1.5]) cube([3, 1.2, 2]);
    // slide switch lever slot
    translate([sw_xc-2.6, -0.01, sw_zc-1.0]) cube([5.2, wall+0.02, 2.0]);
  }
}

// =========================== LID ====================================
module lid() {
  difference() {
    union() {
      translate([0,0,z_wall]) rbox([W, H, lid_t], r_out);
      // OLED clamp standoffs (press on PCB top, outside the glass)
      for (p = holes) translate([p[0], p[1], z_glass]) cylinder(d=4.2, h=z_wall-z_glass+0.01);
      // alignment skirt inside the walls
      translate([0,0,z_wall-1.5]) difference() {
        translate([wall+0.15, wall+0.15, 0]) rbox([in_w-0.3, in_h-0.3, 1.51], 0.9);
        translate([wall+0.95, wall+0.95, -1]) rbox([in_w-1.9, in_h-1.9, 4], 0.5);
      }
    }
    // display window with chamfer
    translate([cx, cy, z_wall-0.01]) hull() {
      translate([0,0,0]) cube([aa_w+1.0, aa_h+1.0, 0.02], center=true);
      translate([0,0,lid_t+0.02]) cube([aa_w+2.4, aa_h+2.4, 0.02], center=true);
    }
    // countersunk M2 holes
    for (p = holes) translate([p[0], p[1], 0]) {
      translate([0,0,z_glass-1]) cylinder(d=2.3, h=Ht);
      translate([0,0,Ht-1.1]) cylinder(d1=2.3, d2=4.3, h=1.11);
    }
  }
}

// ========================= BUTTON CAP ===============================
module cap(x=0) { // assembled position
  translate([x, H-wall-cap_fl, btn_zc]) rotate([-90,0,0]) {
    cap_print();
  }
}
module cap_print() { // flat on bed
  translate([-cap_sq/2, -cap_sq/2, 0]) cube([cap_sq, cap_sq, cap_fl]);
  cylinder(d=4.0, h=cap_fl+wall+0.6);
  translate([0,0,cap_fl+wall+0.6]) cylinder(d1=4.0, d2=3.2, h=0.4);   // sticks out 1.0 mm
}

// ======================== TEST-FIT COUPON ===========================
// 1.2 mm plate: OLED hole pattern pins + window outline + USB opening
module test_fit() {
  difference() {
    rbox([W, H, 1.2], r_out);
    translate([cx, cy, 0]) cube([aa_w+1.0, aa_h+1.0, 4], center=true);
  }
  for (p = holes) translate([p[0], p[1], 0]) { cylinder(d=4.2, h=2.2); cylinder(d=hole_d-0.4, h=4.0); }
  // USB-C wall sample: try a cable through it
  translate([-16, cy-9, 0]) difference() {
    cube([wall-pocket_d+0.8, 18, 12]);
    translate([-0.5, 9, 6]) rrect_x(12.4, 6.8, 2.0, 3);
  }
  translate([-16, cy-9, 0]) cube([10, 18, 1.2]);
}

// ======================== COMPONENT MODELS ==========================
module oled_pcb()  difference() { translate([wall+clr, wall+clr, z_oled]) cube([oled_w, oled_h, oled_t]);
                                   for (p=holes) translate([p[0],p[1],z_oled-1]) cylinder(d=hole_d, h=4); }
module oled_glass() translate([cx-glass_w/2, cy-glass_h/2, z_glass]) difference() {
                       cube([glass_w, glass_h, glass_t]);
                       translate([(glass_w-aa_w)/2, (glass_h-aa_h)/2, glass_t-0.05]) cube([aa_w, aa_h, 1]); }
module oled_aa()   translate([cx-aa_w/2, cy-aa_h/2, z_glass+glass_t-0.05]) cube([aa_w, aa_h, 0.05]);
module oled_back() { // components on rear: regulator, caps, FPC
  translate([cx-12, cy+6, z_oled-oled_back]) cube([24, 5, oled_back]);
  translate([cx+16, cy-6, z_oled-1.2]) cube([4, 3, 1.2]);
  translate([cx-20, cy-6, z_oled-1.2]) cube([3, 4, 1.2]);
}
module oled_pads() for (i=[0:6]) translate([cx-7.62+i*2.54, wall+clr+oled_h-2.6, z_oled-0.02])
                     difference(){ cylinder(d=1.8, h=oled_t+0.04, $fn=16); translate([0,0,-1]) cylinder(d=1.0,h=4,$fn=12);}

module mcu_pcb()   difference() { translate([mcu_x0, mcu_y0, mcu_z0]) cube([mcu_l, mcu_w, mcu_t]);
                     for (i=[0:7], y=[mcu_y0+1.27, mcu_y0+mcu_w-1.27]) translate([mcu_x0+3.0+i*2.54, y, mcu_z0-1]) cylinder(d=1.0, h=4, $fn=12); }
module mcu_pads()  for (i=[0:7], y=[mcu_y0+1.27, mcu_y0+mcu_w-1.27]) translate([mcu_x0+3.0+i*2.54, y, mcu_z0-0.02])
                     difference(){ cylinder(d=1.7, h=mcu_t+0.04, $fn=16); translate([0,0,-1]) cylinder(d=1.0,h=4,$fn=12);}
module mcu_usb()   translate([usb_x0, cy, mcu_z0+mcu_t]) hull() for (z=[usb_h/2-0.01]) for (s=[-1,1])
                     translate([0, s*(usb_w/2-usb_h/2), usb_h/2]) rotate([0,90,0]) cylinder(d=usb_h, h=usb_l, $fn=24);
module mcu_chip()  translate([mcu_x0+12, cy-2.5, mcu_z0+mcu_t]) cube([5, 5, 0.9]);
module mcu_parts() { translate([mcu_x0+19.3, cy-1.6, mcu_z0+mcu_t]) cube([2.2, 3.2, 1.0]);      // ceramic antenna
                     translate([mcu_x0+8.8, cy+3.2, mcu_z0+mcu_t]) cube([3.0, 1.6, 1.1]);       // LDO
                     for (y=[mcu_y0+3.2, mcu_y0+mcu_w-6.2]) translate([mcu_x0+8.6, y, mcu_z0+mcu_t]) cube([3.0, 3.0, 1.4]); // BOOT/RST
                     translate([mcu_x0+17.5, cy+3.5, mcu_z0+mcu_t]) cube([3.2, 2.5, 0.8]); }    // crystal
module mcu_antenna() translate([mcu_x0+19.3, cy-1.6, mcu_z0+mcu_t]) cube([2.2, 3.2, 1.0]);

module battery()   translate([bat_x0, bat_y0, z_bat]) rbox([bat_l, bat_w, bat_t], 1.0);
module bat_tape()  translate([bat_x0, bat_y0, z_bat]) difference() { cube([bat_l, bat_w, bat_t]); translate([0.5,0.5,-1]) cube([bat_l-1, bat_w-1, bat_t+2]); }
module bat_foam()  translate([bat_x0+4, bat_y0+4, z_bat+bat_t]) cube([bat_l-8, bat_w-8, tape]);  // 1 mm foam, compressed
module chg_pcb()   translate([chg_x0, chg_y0, z_chg]) cube([chg_l, chg_w, chg_t]);
module chg_usb()   translate([chg_x0+chg_l+0.6-7.35, chg_y0+chg_w/2, z_chg+chg_t]) hull() for (s=[-1,1])
                     translate([0, s*(usb_w/2-usb_h/2), usb_h/2]) rotate([0,90,0]) cylinder(d=usb_h, h=7.35, $fn=24);
module chg_chips() { translate([chg_x0+8, chg_y0+5, z_chg+chg_t]) cube([5, 4, 1.5]);          // TP4056
                     translate([chg_x0+2.5, chg_y0+3, z_chg+chg_t]) cube([3, 3, 1.1]);         // DW01
                     translate([chg_x0+2.5, chg_y0+10, z_chg+chg_t]) cube([3, 3, 1.1]);        // FS8205
                     translate([chg_x0+15, chg_y0+11, z_chg+chg_t]) cube([2, 1.2, 0.8]); }
module chg_pads()  for (p=[[1.2,1.6],[1.2,chg_w-1.6],[chg_l-1.8,1.6],[chg_l-1.8,chg_w-1.6]])
                     translate([chg_x0+p[0]-0.9, chg_y0+p[1]-0.9, z_chg+chg_t]) cube([1.8,1.8,0.05]);

module button_body(x) translate([x-btn/2, btn_y0, btn_zc-btn/2]) cube([btn, btn_body, btn]);
module button_top(x)  translate([x-btn/2+0.3, btn_y0+btn_body-0.3, btn_zc-btn/2+0.3]) cube([btn-0.6, 0.31, btn-0.6]);
module button_stem(x) translate([x, btn_y0+btn_body, btn_zc]) rotate([-90,0,0]) cylinder(d=3.5, h=btn_total-btn_body);
module buttons_body() for (x=btn_xs) button_body(x);
module buttons_top()  for (x=btn_xs) button_top(x);
module buttons_stem() for (x=btn_xs) button_stem(x);
module caps()         for (x=btn_xs) cap(x);

module sw_body()  translate([sw_xc-sw_l/2, wall, floor_t]) cube([sw_l, sw_d, sw_h]);
module sw_lever() translate([sw_xc-0.8-0.75, wall-sw_lever, sw_zc-0.75]) cube([1.6, sw_lever, 1.5]);
module powerpath() translate([pp_x0, pp_y0, floor_t]) cube(pp);
module screws() for (p=holes) translate([p[0], p[1], 0]) {
                  translate([0,0,Ht-12]) cylinder(d=1.95, h=12-1.0);
                  translate([0,0,Ht-1.0]) cylinder(d1=1.95, d2=3.9, h=1.0); }

// ========================= SELECTOR =================================
module show(name) {
  if (name=="base") base();
  else if (name=="base_nosnap") base(false);
  else if (name=="snaps") snaps();
  else if (name=="lid") lid();
  else if (name=="caps") caps();
  else if (name=="cap") cap_print();
  else if (name=="test_fit") test_fit();
  else if (name=="oled_pcb") oled_pcb();
  else if (name=="oled_glass") oled_glass();
  else if (name=="oled_aa") oled_aa();
  else if (name=="oled_back") oled_back();
  else if (name=="oled_pads") oled_pads();
  else if (name=="mcu_pcb") mcu_pcb();
  else if (name=="mcu_pads") mcu_pads();
  else if (name=="mcu_usb") mcu_usb();
  else if (name=="mcu_chip") mcu_chip();
  else if (name=="mcu_parts") mcu_parts();
  else if (name=="battery") battery();
  else if (name=="bat_foam") bat_foam();
  else if (name=="chg_pcb") chg_pcb();
  else if (name=="chg_usb") chg_usb();
  else if (name=="chg_chips") chg_chips();
  else if (name=="chg_pads") chg_pads();
  else if (name=="buttons_body") buttons_body();
  else if (name=="buttons_top") buttons_top();
  else if (name=="buttons_stem") buttons_stem();
  else if (name=="sw_body") sw_body();
  else if (name=="sw_lever") sw_lever();
  else if (name=="powerpath") powerpath();
  else if (name=="screws") screws();
}

if (part == "assembly") {
  color("WhiteSmoke") base();
  color("WhiteSmoke", 0.4) lid();
  color("Orange") caps();
  color("RoyalBlue") oled_pcb(); color("#111") oled_glass();
  color("#1b2a6b") mcu_pcb(); color("Silver") mcu_usb(); color("#222") mcu_chip();
  color("Silver") battery(); color("#2b59c3") chg_pcb(); color("Silver") chg_usb();
  color("#222") buttons_body(); color("#222") sw_body(); color("Silver") sw_lever();
  color("Green") powerpath(); color("Gray") screws();
} else if (part == "dims") {
  echo(str("OUTER W=", W, " H=", H, " T=", Ht));
  echo(str("z_oled=", z_oled, " z_wall=", z_wall));
} else show(part);
