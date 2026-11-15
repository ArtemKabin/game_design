# 0036: Game 3: the real dorm and campus outside, scene change through portals

* Date: 2026-11-15
* Status: accepted
* Participants: Person A, Person B

## Context
The player can now leave the dorm. Outside should be a 1:1 copy of our real dorm complex (house 17, where the main character lives, entrance F, 4th floor, and houses 15, 13, 11) and of the surrounding university campus. Two earlier attempts were rejected: a free-form exterior, and a first OSM version that was rotated by 4°, missed buildings mapped as relations, drew roads as loose rectangles and let meshes overlap.

## Decision
Inside and outside are separate scenes. `scripts/portal.gd` (extends Interactable) costs time like any action (2 min of stairs), then `GameState.travel()` loads the target scene and `scripts/level.gd` on the scene root puts the player at the Marker3D `Spawns/<name>`.

`scripts/site.gd` generates the whole outside from `data/hka_site.json`, which is derived from OpenStreetMap (street names removed). Coordinates are map coordinates, north up, not rotated, so the result lines up with a web map. Play area: the big street with car parks in the north, Moltkestraße in the south, the long building LI (left of E, F, M) in the west, Mensa Moltke in the east. The generated map is cut to a rectangle just around it (x −320…225, z −210…235); only buildings fully inside are kept, areas and roads are clipped at the edge.
* Buildings (`scripts/site_building.gd`): real outlines including multipolygon relations with courtyards, real floor counts. House 17 has its exact OSM outline, 4 floors over the open car park (1.3 m plinth). Its six entrances A–F (glass stairwell front, door, 8 steps) face the shared footway between 17 and 11/13/15; 17F is the southernmost. Houses 11/13/15 have their doors on the same footway.
* Roads and paths: one connected polyline per way with a quad per segment and a disc at every point, so bends and junctions are round and connected ways join without gaps. Paths lie below car roads, so roads run through crossings and path ends disappear under the asphalt. Paths are clipped where they would run through a building. Car-road widths are limited so they never overlap a parallel sidewalk.
* Ground areas and roads each have their own layer, 6 mm apart and all below walking height (`site.gd` LAYER_ORDER); the camera's near plane grows with the zoom (`camera_rig.gd`), so nothing z-fights even far out. Windows, floor bands, glass fronts and doors sit a few centimetres in front of the walls.
* Doors at the real entrances from OSM (entrance nodes snapped to the nearest wall; named buildings without a mapped entrance get one door facing the nearest path). Every door except 17F only shows "Hier wird noch gearbeitet." for now.
* Cars are parked in rows along the real parking aisles; every car is checked against the lot outline, roads, buildings and other cars (exact rectangle overlap). Trees fill forest and grass areas and keep clear of buildings, roads, barriers, car parks and each other. Hedges, fences and walls from OSM have collision. No street lamps.

The map view (M) shows the whole map from above; holding a mouse button drags it, limited to the map rectangle.

`RoomView` also works outdoors: without zones it uses the player's position, and a building is cut down to its stub while the player stands right behind (north of) it.

## Consequences
Outlines are as accurate as OpenStreetMap; checked against an aerial image, OSM is within about 5 m (Google's rendering of Moltkestraße is about 10 m further south). Facades are greybox colours with generated windows. The 4th-floor plan inside is not yet aligned with the real section F of house 17. Trees and cars are MultiMeshes (well above 60 fps). Trees have no collision; parked cars do. The generator scripts that turn OSM into the JSON are not in the repo yet.
