# VR Mobile Camera
This node plug-in for Gotot Engine enable a new kind of 3D camera, you can use it with phone vr headset or cardboard.<br>
It provide screen split for stereoscopic vision and head tracking by using accelerometer and gyroscope sensor on the phone, if gyroscope is not found, magnetometer will be used as fall back.<br>
Gyroscope data are matched with accelerometer data so to have a very accurate and responsive tracking, unfortunately only hi-end phones provide gyroscope, so, magnetometer is supported too.<br>
Magnetometer outputs a very noisy data, so, the signal is filtered in order to make it usable. The drawback of filtering data is that you introduce a lag. You can balance noise and lag by modifying the Magnetometer Interpolation parameter in the camera inspector.<br>
<br>
# VR Camera Parameters
You can set some camera parameter in the inspector panel inside Godot.<br>
You can set Eyes Distance and Eyes Convergence.<br>
The camera can moves on the plane if you push the visor up and down, the speed is set by the Walking Speed parameter.<br>
Fow, Near and Far just work as on regular 3D camera.<br>
Magnetometer Interpolation sets the number of frames to be taken in count for interpolating data, the higher is the number the smoother is the view but increments the lag.<br>
You can lock an axis rotation by unchecking Enable Yaw, Enable Pitchand Enable Roll.<br>
Show Data check showd sensors data during runtime and is mainly for debugging purposes.<br>
<br>
The plug in was tested successfully on Android devices.<br>
There is initial iOS support but it seems Godot can't access magnometer and gyroscope data on such OS so it's not very usefull on Apple devices right now.<br>
