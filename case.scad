// =====================================================================
//  OLED Gift Box  v2  (built around the measured parts)
//  ESP32-C3 SuperMini + M242OLED (2.42" SSD1309, 72.5 x 44 board)
//  + 1000 mAh LiPo 50x22x7 with its own micro-USB charger/switch board
//  + 2x 6x6 buttons.  Snap-on lid, NO screws.  All units mm.
//
//  openscad -D 'part="base"' -o base.stl case.scad
// =====================================================================
part = "assembly";
$fn = 40;

// ---------- OLED (M242OLED) - measured --------------------------------
oled_l = 72.5; oled_w = 44.0; oled_t = 1.6;   // board; pins on a short edge
hole_in = 2.0; hole_d = 3.0;                   // hole centre 2 mm from both edges
glass_l = 62.0; glass_w = 39.5;                // black glass
glass_u0 = 6.0;                                // pin edge -> glass
glass_v0 = 2.0;                                // long edge -> glass
glass_t = 3.4;                                 // glass height above board (up to 5 is fine: it pokes through the window)
oled_back = 3.5;                               // tallest part on the back (coil, FPC connector)
hdr_drop = 4.0;                                // pin-header plastic + pins cut short, below the board

// ---------- ESP32-C3 SuperMini - measured -----------------------------
mcu_l = 23; mcu_w = 18; mcu_t = 1.0;
usb_w = 8.94; usb_h = 3.26; usb_l = 7.35; usb_over = 0.6;
mcu_raise = 1.5;                               // room for cut-off header stubs underneath

// ---------- battery + its charger board - measured ---------------------
bat_l = 50; bat_w = 22; bat_t = 7.0; foam = 0.6;
cb_l = 20; cb_w = 10; cb_t = 3.0; cb_pcb = 1.0;  // charger board (micro-USB + 3-pin socket on one long edge)
cb_usb_c = 4.7;  cb_sw_c = 15.2;               // micro-USB and socket centres along that edge
cb_sock_h = 4.0;                               // 3-pin socket height above the board

btn = 6.0; btn_body = 3.5; btn_total = 5.0;    // 6x6x5 tactile switch

// ---------- case ----------
clr = 0.3; wall = 2.0; floor_t = 1.6; lid_t = 1.6; r_out = 3.0; fit = 0.15;
so_h = 2.0;                                    // lid posts: board top -> lid underside

in_w = oled_l + 2*clr;  in_h = oled_w + 2*clr;
W = in_w + 2*wall;      H = in_h + 2*wall;
z_oled  = floor_t + bat_t + foam + 0.3 + oled_back;   // OLED board bottom
z_ptop  = z_oled + oled_t;
z_wall  = z_ptop + so_h;
Ht      = z_wall + lid_t;

ox = wall + clr; oy = wall + clr;              // OLED board origin (pin edge at -X)
holes = [for (u=[hole_in, oled_l-hole_in], v=[hole_in, oled_w-hole_in]) [ox+u, oy+v]];
gx0 = ox + glass_u0; gy0 = oy + glass_v0;

// SuperMini: USB-C in the -X wall, upper half
pocket_d = 1.0;
mcu_x0 = wall - pocket_d;  usb_x0 = mcu_x0 - usb_over;
mcu_y0 = 26.6;  mcu_cy = mcu_y0 + mcu_w/2;
mcu_z0 = floor_t + mcu_raise;
usb_zc = mcu_z0 + mcu_t + usb_h/2;
stop_x0 = mcu_x0 + mcu_l + 0.2; stop_t = 1.2;

// battery: lower half, against the -Y wall
bat_x0 = 8.3; bat_y0 = wall + clr;  bat_x1 = bat_x0 + bat_l; bat_y1 = bat_y0 + bat_w;

// charger board: long edge (micro-USB) in a pocket of the +X wall
cb_pd = 1.0;
cb_x1 = W - wall + cb_pd;  cb_x0 = cb_x1 - cb_w;
cb_y0 = 7.2;  cb_y1 = cb_y0 + cb_l;
cb_usb_y = cb_y0 + cb_usb_c;  cb_sw_y = cb_y0 + cb_sw_c;
cb_ztop = floor_t + cb_pcb;

// buttons: pressed through the +Y wall
cap_fl = 0.9; cap_sq = 5.2;
btn_xs = [36, 50];
rib_y0 = H - wall - cap_fl - btn_total - 1.0;  btn_y0 = rib_y0 + 1.0;
btn_zc = floor_t + btn/2;

// diode (SS14 in heat-shrink) lives in the free middle area
dio = [7, 3, 3]; dio_x0 = 30; dio_y0 = 29;

// lid snap bumps
snap_z = z_wall - 0.9;
snaps_x = [W*0.3, W*0.7];

// ====================================================================
module rbox(s, r) { hull() for (x=[r, s[0]-r], y=[r, s[1]-r]) translate([x,y,0]) cylinder(r=r, h=s[2]); }
module rrect_x(w, h, r, len) { rotate([0,90,0]) hull() for (a=[-1,1], b=[-1,1]) translate([a*(h/2-r), b*(w/2-r), 0]) cylinder(r=r, h=len); }
module peg(p) translate([p[0], p[1], z_oled-0.01]) {
  cylinder(d=hole_d-0.4, h=oled_t+so_h-0.5);
  translate([0,0,oled_t+so_h-0.5]) cylinder(d1=hole_d-0.4, d2=hole_d-1.2, h=0.4);
}

// ------------------------- snap features of the base -----------------
module snaps() {
  // SuperMini hooks over its back corners
  for (y = [mcu_y0, mcu_y0+mcu_w-2.4])
    translate([stop_x0, y, mcu_z0+mcu_t+0.1])
      hull() { translate([-0.7,0,0]) cube([0.71, 2.4, 0.3]); translate([0,0,0.8]) cube([0.01,2.4,0.01]); }
  // nubs over the tactile switches
  for (x = btn_xs) for (s=[-1,1])
    translate([s<0 ? x-btn/2-fit : x+btn/2+fit-0.35, btn_y0+0.5, floor_t+btn+0.05]) cube([0.35, btn_body-1, 0.3]);
  // charger board: nubs over its back corners + ramp catch behind it
  for (y = [cb_y0-fit, cb_y1+fit-0.35]) translate([cb_x0, y, cb_ztop+0.05]) cube([1.5, 0.35, 0.3]);
  translate([cb_x0-fit-1.6, cb_y0+3, floor_t-0.01]) hull() { translate([1.0,0,0]) cube([0.6, cb_l-6, 0.51]); cube([1.6, cb_l-6, 0.01]); }
}

// ------------------------------ BASE ---------------------------------
module base(with_snaps=true) {
  difference() {
    union() {
      difference() {
        rbox([W, H, z_wall], r_out);
        translate([wall, wall, floor_t]) rbox([in_w, in_h, z_wall], 1.0);
      }
      // 3 posts from the floor; the one above the SuperMini hangs from the corner walls
      for (i=[0,2,3]) translate([holes[i][0], holes[i][1], 0]) cylinder(d=5.2, h=z_oled);
      hull() {
        translate([holes[1][0], holes[1][1], 9.0]) cylinder(d=5.2, h=z_oled-9.0);
        translate([holes[1][0]-2.6, H-wall-0.01, 9.0-4.6]) cube([5.2, 0.01, z_oled-9.0+4.6]);
      }
      for (p = holes) peg(p);
      // ---- SuperMini cradle ----
      for (y = [mcu_y0+5.0, mcu_y0+11.5]) translate([wall+2, y, floor_t-0.01]) cube([mcu_l-4, 1.5, mcu_raise+0.01]);
      for (y = [mcu_y0-fit-1.0, mcu_y0+mcu_w+fit])
        translate([wall+1, y, floor_t-0.01]) cube([mcu_l-3, 1.0, mcu_z0+mcu_t+0.8-floor_t]);
      difference() {
        translate([stop_x0, mcu_y0-1.2, floor_t-0.01]) cube([stop_t, mcu_w+2.4, mcu_z0+mcu_t+0.9-floor_t]);
        translate([stop_x0, mcu_cy, mcu_z0+mcu_t+0.9]) rotate([0,45,0]) cube([1.2, mcu_w+4, 1.2], center=true);
      }
      // ---- battery pocket (the case wall is its 4th side) ----
      difference() {
        translate([bat_x0-1.1, wall-0.01, floor_t-0.01]) cube([bat_l+2.2, bat_w+2*clr+0.8+0.01, 5.0]);
        translate([bat_x0-0.3, wall-0.1, floor_t-0.1]) cube([bat_l+0.6, bat_w+2*clr+0.1, 10]);
        for (x=[bat_x0-1.2, bat_x1+0.2]) translate([x, bat_y0+6, floor_t+2.5]) cube([1.1, bat_w-12, 5]);  // wire notches
      }
      // ---- button pockets + back rib ----
      translate([btn_xs[0]-4.5, rib_y0, floor_t-0.01]) cube([btn_xs[1]-btn_xs[0]+9, 1.0, btn+0.3]);
      for (x = btn_xs) for (s=[-1,1])
        translate([x + s*(btn/2+fit) + (s<0 ? -1.0 : 0), btn_y0, floor_t-0.01]) cube([1.0, H-wall-btn_y0+0.01, btn+0.35]);
      // ---- charger board pocket side walls ----
      for (y = [cb_y0-fit-1.0, cb_y1+fit])
        translate([cb_x0-0.5, y, floor_t-0.01]) cube([W-wall-cb_x0+0.51, 1.0, cb_t+0.4]);
      if (with_snaps) snaps();
    }
    // SuperMini USB-C: wall pocket (PCB slot + socket slot under a lip) and plug opening
    translate([wall-pocket_d, mcu_y0-0.2, mcu_z0-0.2]) cube([pocket_d+0.01, mcu_w+0.4, mcu_t+0.4]);
    translate([wall-pocket_d, mcu_cy-usb_w/2-0.2, mcu_z0-0.2]) cube([pocket_d+0.01, usb_w+0.4, mcu_t+usb_h+0.34]);
    translate([-0.01, mcu_cy, usb_zc]) rrect_x(12.4, 6.8, 2.0, wall-pocket_d+0.02);
    // charger board: wall pocket for its edge + micro-USB opening
    translate([W-wall-0.01, cb_y0-fit, floor_t-0.01]) cube([cb_pd+0.01, cb_l+2*fit, cb_t+0.3]);
    translate([W-(wall-cb_pd)-0.01, cb_usb_y, cb_ztop+1.3]) rrect_x(11.0, 6.5, 2.0, wall);
    // lid snap grooves in the walls
    for (x = snaps_x) for (y = [wall-0.5, H-wall-0.01]) translate([x-6, y, snap_z-0.5]) cube([12, 0.51, 1.0]);
    translate([wall-0.5, H/2-6, snap_z-0.5]) cube([0.51, 12, 1.0]);
    // pry notch for opening the lid
    translate([W/2-5, -0.01, z_wall-1.0]) cube([10, 0.8, 1.01]);
    // button plunger holes
    for (x = btn_xs) translate([x, H-wall-0.01, btn_zc]) rotate([-90,0,0]) cylinder(d=4.3, h=wall+0.02);
  }
}

// ------------------------------- LID ---------------------------------
module lid_body() {
  difference() {
    union() {
      translate([0,0,z_wall]) rbox([W, H, lid_t], r_out);
      for (p = holes) translate([p[0], p[1], z_ptop]) cylinder(d=4.2, h=so_h+0.01);
      // skirt inside the walls, above the OLED board
      translate([0,0,z_ptop+0.2]) difference() {
        translate([wall+fit, wall+fit, 0]) rbox([in_w-2*fit, in_h-2*fit, z_wall-z_ptop-0.19], 0.9);
        translate([wall+fit+1.0, wall+fit+1.0, -1]) rbox([in_w-2*fit-2.0, in_h-2*fit-2.0, 5], 0.5);
      }
    }
    // window = glass outline + 0.5 (the glass may poke through)
    translate([gx0-0.5, gy0-0.5, z_ptop]) cube([glass_l+1.0, glass_w+1.0, 10]);
    translate([gx0-0.5, gy0-0.5, Ht-0.6]) hull() {
      cube([glass_l+1.0, glass_w+1.0, 0.01]);
      translate([-0.6,-0.6,0.6]) cube([glass_l+2.2, glass_w+2.2, 0.01]);
    }
    // sockets for the pegs
    for (p = holes) translate([p[0], p[1], z_ptop-0.01]) cylinder(d=hole_d, h=so_h+0.4);
  }
}
module lid_snaps() {
  for (x = snaps_x) for (s=[-1,1])
    translate([x-5, s<0 ? wall+fit-0.35 : H-wall-fit-0.01, snap_z-0.35]) cube([10, 0.36, 0.7]);
  translate([wall+fit-0.35, H/2-5, snap_z-0.35]) cube([0.36, 10, 0.7]);
}
module lid() { lid_body(); lid_snaps(); }

// --------------------------- BUTTON CAP ------------------------------
module cap_print() {
  translate([-cap_sq/2, -cap_sq/2, 0]) cube([cap_sq, cap_sq, cap_fl]);
  cylinder(d=4.0, h=cap_fl+wall+0.6);
  translate([0,0,cap_fl+wall+0.6]) cylinder(d1=4.0, d2=3.2, h=0.4);
}
module caps()  for (x=btn_xs) translate([x, H-wall-cap_fl, btn_zc]) rotate([-90,0,0]) cap_print();
module caps_print() for (i=[0,1]) translate([i*(cap_sq+4), 0, 0]) cap_print();

// ------------------------- COMPONENT MODELS --------------------------
module oled_pcb() difference() {
  translate([ox, oy, z_oled]) cube([oled_l, oled_w, oled_t]);
  for (p=holes) translate([p[0],p[1],z_oled-1]) cylinder(d=hole_d, h=4);
  translate([ox+oled_l-24, oy+oled_w-1.2, z_oled-1]) cube([14, 1.3, 4]);   // FPC slot
}
module oled_glass() translate([gx0, gy0, z_ptop]) cube([glass_l, glass_w, glass_t]);
module oled_back() {
  translate([ox+30, oy+12, z_oled-2.5]) cube([5, 20, 2.5]);         // FPC connector
  translate([ox+35, oy+16, z_oled-0.6]) cube([25, 12, 0.6]);        // ribbon
  translate([ox+48, oy+3, z_oled-oled_back]) cube([4.5, 4.5, oled_back]); // coil
  for (y=[oy+9, oy+13]) translate([ox+52, y, z_oled-2.0]) cube([3.5, 3, 2.0]); // tantalum caps
}
module oled_hdr() translate([ox+1.25, oy+oled_w/2-8.9, z_oled-hdr_drop]) cube([2.5, 17.8, hdr_drop]);

module mcu_pcb()   translate([mcu_x0, mcu_y0, mcu_z0]) cube([mcu_l, mcu_w, mcu_t]);
module mcu_pads()  for (i=[0:7], y=[mcu_y0+1.27, mcu_y0+mcu_w-1.27]) translate([mcu_x0+3.2+i*2.54, y, mcu_z0-0.02]) cylinder(d=1.7, h=mcu_t+0.04, $fn=16);
module mcu_usb()   translate([usb_x0, mcu_cy, mcu_z0+mcu_t]) hull() for (s=[-1,1])
                     translate([0, s*(usb_w/2-usb_h/2), usb_h/2]) rotate([0,90,0]) cylinder(d=usb_h, h=usb_l, $fn=24);
module mcu_chip()  translate([mcu_x0+11.5, mcu_cy-2.5, mcu_z0+mcu_t]) cube([5, 5, 0.9]);
module mcu_parts() { for (y=[mcu_cy-3.8, mcu_cy+0.8]) translate([mcu_x0+8.2, y, mcu_z0+mcu_t]) cube([3.0, 3.0, 1.4]);
                     translate([mcu_x0+19.5, mcu_cy+3.0, mcu_z0+mcu_t]) cube([2.6, 2.0, 0.8]);
                     translate([mcu_x0+19.8, mcu_cy-5.5, mcu_z0+mcu_t]) cube([1.5, 3.5, 0.8]); }

module battery()  translate([bat_x0, bat_y0, floor_t]) rbox([bat_l, bat_w, bat_t], 1.2);
module bat_foam() translate([bat_x0+6, bat_y0+4, floor_t+bat_t]) cube([bat_l-12, bat_w-8, foam]);
module cb_pcb()   translate([cb_x0, cb_y0, floor_t]) cube([cb_w, cb_l, cb_pcb]);
module cb_usb()   translate([cb_x1-5.2, cb_usb_y-3.75, cb_ztop]) cube([5.2, 7.5, cb_t-cb_pcb]);
module cb_sw()    translate([cb_x1-4.7, cb_sw_y-4.0, cb_ztop]) difference() {  // 3-pin female socket
                     cube([3.5, 8.0, cb_sock_h]);
                     for (i=[-1:1]) translate([1.75-0.5, 4+i*2.54-0.5, cb_sock_h-2]) cube([1, 1, 3]); }
module cb_chips() { translate([cb_x0+1.5, cb_y0+8, cb_ztop]) cube([3, 3, 1.0]); translate([cb_x0+1.5, cb_y0+13, cb_ztop]) cube([2, 1.2, 0.6]); }

module buttons_body() for (x=btn_xs) translate([x-btn/2, btn_y0, btn_zc-btn/2]) cube([btn, btn_body, btn]);
module buttons_top()  for (x=btn_xs) translate([x-btn/2+0.3, btn_y0+btn_body-0.3, btn_zc-btn/2+0.3]) cube([btn-0.6, 0.31, btn-0.6]);
module buttons_stem() for (x=btn_xs) translate([x, btn_y0+btn_body, btn_zc]) rotate([-90,0,0]) cylinder(d=3.5, h=btn_total-btn_body);
module diode()  translate([dio_x0, dio_y0, floor_t]) cube(dio);

// ----------------------------- SELECTOR ------------------------------
module show(n) {
  if (n=="base") base(); else if (n=="base_nosnap") base(false); else if (n=="snaps") snaps();
  else if (n=="lid") lid(); else if (n=="lid_nosnap") lid_body(); else if (n=="lid_snaps") lid_snaps();
  else if (n=="caps") caps(); else if (n=="cap") cap_print(); else if (n=="caps_print") caps_print();
  else if (n=="oled_pcb") oled_pcb(); else if (n=="oled_glass") oled_glass();
  else if (n=="oled_back") oled_back(); else if (n=="oled_hdr") oled_hdr();
  else if (n=="mcu_pcb") mcu_pcb(); else if (n=="mcu_pads") mcu_pads(); else if (n=="mcu_usb") mcu_usb();
  else if (n=="mcu_chip") mcu_chip(); else if (n=="mcu_parts") mcu_parts();
  else if (n=="battery") battery(); else if (n=="bat_foam") bat_foam();
  else if (n=="cb_pcb") cb_pcb(); else if (n=="cb_usb") cb_usb(); else if (n=="cb_sw") cb_sw();
  else if (n=="cb_chips") cb_chips();
  else if (n=="buttons_body") buttons_body(); else if (n=="buttons_top") buttons_top(); else if (n=="buttons_stem") buttons_stem();
  else if (n=="diode") diode();
}
if (part == "assembly") {
  color("Plum") base(); color("Plum", 0.4) lid(); color("White") caps();
  color("RoyalBlue") oled_pcb(); color("#111") oled_glass(); color("#333") oled_hdr();
  color("#222") mcu_pcb(); color("Silver") mcu_usb();
  color("Silver") battery(); color("Green") cb_pcb(); color("Silver") cb_usb(); color("#222") cb_sw();
  color("#222") buttons_body(); color("Orange") diode();
} else if (part == "dims") {
  echo(str("OUTER W=", W, " H=", H, " T=", Ht, " z_oled=", z_oled));
} else show(part);
