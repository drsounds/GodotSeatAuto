# GodotSeatAuto Demo
This is a template that combines the functionality of the [3d Car With Settingspanel](https://godotengine.org/asset-library/asset/661) by Aaron Franke and the playable character from [Godot Third Person Shooter](https://godotengine.org/asset-library/asset/716) by JohnnyRouddro assets to resemble a simple GTA like functionality that allows the Player to enter and disembark a car.

## Docs
TBA

# Description

This mod augments the Car.gd class of the 3d car with a set of new functions and members. First it adds an array list of passengers that can enter and disembark the vehicle and two methods to allow that, get_into_car and get_out_of_car. It also adds a generic function called 'use' which is called by nearby player objects with the Input 'use'.
It also mods the Player entity taken from the Godot Third Person demo to allow it to use objects nearby with the key 'use'.
* get_out_of_car(passenger: Node) -> void - Makes a certain player get out of car
* get_in_of_car(passenger: Node, is_driver : bool) -> void - Let the passenger enter the vehicle.
* use(node : Node) -> void - Calls the get_in_of_car

With Node I mean the reference to the instance of the playable character Scene, Player.gd.

I also added an additional camera to the vehicle that adds possible to view from the rear of the car. The view is toggled with the inåut key 'toggle_view'.
# Credits
## Mod author

Alexander Forselius <drsounds@gmail.com>

## Original assets

Aaron Franke - 3d Car with Settingspanel

JohnnyRouddro - Third Person Shooter

# License

MIT (All assets used is public domain)
