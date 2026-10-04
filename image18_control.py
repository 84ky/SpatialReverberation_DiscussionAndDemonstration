"""Experimental image-source control frames for a future OSC-enabled DSP.

The coordinate system is x = forward, y = right, z = up.  Yaw is in degrees
around z (zero looks along +x); positive pitch looks up.  Distances are
metres and delays are seconds.
This module uses only the Python standard library, so it can run in a
TouchDesigner Text DAT as well as in a regular Python interpreter.
The current kendall_martens_decker.dsp has fixed delays and no matching OSC
controls; sending these frames will not change that DSP.
"""

from math import atan2, cos, isfinite, pi, sin, sqrt

SPEED_OF_SOUND = 344.0
MAX_DELAY_SECONDS = 2.0
OSC_ROOT = "/KendallMartensDecker"

# Order is shared with the Faust program.
FIRST_IMAGES = (
    (1, 0, 0), (0, 1, 0), (-1, 0, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)
)
SECOND_IMAGES = (
    (1, 1, 0), (-1, 1, 0), (-1, -1, 0), (1, -1, 0),
    (1, 0, 1), (-1, 0, 1), (-1, 0, -1), (1, 0, -1),
    (0, 1, 1), (0, -1, 1), (0, -1, -1), (0, 1, -1),
)
WALLS = ((0, 1), (1, 1), (0, -1), (1, -1), (2, 1), (2, -1))
DEFAULT_ROOM = (6.2, 12.3, 8.0)
DEFAULT_SOURCE = (2.0, 4.0, 1.5)
DEFAULT_LISTENER = (3.2, 6.1, 1.7)
DEFAULT_REFLECTION = (0.75,) * 6


def _wall_index(axis, sign):
    return WALLS.index((axis, sign))


def _image_coordinate(index, length, source):
    return index * length + (length - source if abs(index) % 2 else source)


def _ray(image, room, source, listener):
    return tuple(
        _image_coordinate(n, size, src) - ear
        for n, size, src, ear in zip(image, room, source, listener)
    )


def _distance(ray):
    return sqrt(sum(component * component for component in ray))


def _pan(ray, yaw_degrees, pitch_degrees):
    # Equal-power stereo panning uses only the left/right projection.  It
    # cannot represent elevation or distinguish front from back by itself.
    yaw = yaw_degrees * pi / 180.0
    pitch = pitch_degrees * pi / 180.0
    forward = cos(pitch) * (ray[0] * cos(yaw) + ray[1] * sin(yaw)) + ray[2] * sin(pitch)
    right = -ray[0] * sin(yaw) + ray[1] * cos(yaw)
    azimuth = atan2(right, forward)
    return max(0.0, min(1.0, 0.5 * (1.0 + sin(azimuth))))


def _gain(distance, reflection_product=1.0):
    # Pressure amplitude in a free field is approximately proportional to 1/r.
    return reflection_product / max(1.0, distance)


def _validate(room, source, listener, reflection):
    if len(room) != 3 or len(source) != 3 or len(listener) != 3 or len(reflection) != 6:
        raise ValueError("room, source and listener need 3 values; reflection needs 6")
    values = tuple(room) + tuple(source) + tuple(listener) + tuple(reflection)
    if not all(isfinite(v) for v in values):
        raise ValueError("all parameters must be finite")
    if not all(size > 0 for size in room):
        raise ValueError("room dimensions must be positive")
    if any(not 0 <= p <= size for p, size in zip(source, room)):
        raise ValueError("source must be inside the room")
    if any(not 0 <= p <= size for p, size in zip(listener, room)):
        raise ValueError("listener must be inside the room")
    if any(not 0 <= r < 1 for r in reflection):
        raise ValueError("wall pressure-reflection factors must be in [0, 1)")


def calculate_frame(
    room=DEFAULT_ROOM,
    source=DEFAULT_SOURCE,
    listener=DEFAULT_LISTENER,
    yaw_degrees=0.0,
    pitch_degrees=0.0,
    reflection=DEFAULT_REFLECTION,
):
    """Return a dict of Faust OSC address to control value for one frame.

    Reflection order and delay are exact for the direct, first-order, and
    twelve edge-adjacent second-order image sources.  The recirculating
    R1/R2 units approximate higher orders as described in chapter 7.
    """
    _validate(room, source, listener, reflection)
    if not isfinite(yaw_degrees) or not isfinite(pitch_degrees):
        raise ValueError("yaw and pitch must be finite")

    def distance(image):
        return _distance(_ray(image, room, source, listener))

    def put(group, index, name, value):
        path = f"{OSC_ROOT}/{group}_{index}/{name}" if index is not None else f"{OSC_ROOT}/{group}/{name}"
        controls[path] = float(value)

    controls = {}
    direct_ray = _ray((0, 0, 0), room, source, listener)
    direct_distance = _distance(direct_ray)
    put("direct", None, "delay_s", direct_distance / SPEED_OF_SOUND)
    put("direct", None, "gain", _gain(direct_distance))
    put("direct", None, "pan", _pan(direct_ray, yaw_degrees, pitch_degrees))

    for i, image in enumerate(FIRST_IMAGES):
        axis, sign = WALLS[i]
        d1 = distance(image)
        image2 = tuple(2 * n for n in image)
        image3 = tuple(3 * n for n in image)
        d2, d3 = distance(image2), distance(image3)
        own = reflection[i]
        opposite = reflection[_wall_index(axis, -sign)]
        put("first", i, "delay_s", d1 / SPEED_OF_SOUND)
        put("first", i, "gain", _gain(d1, own))
        put("first", i, "pan", _pan(_ray(image, room, source, listener), yaw_degrees, pitch_degrees))
        put("first", i, "r2_delay1_s", (d2 - d1) / SPEED_OF_SOUND)
        put("first", i, "r2_delay2_s", (d3 - d2) / SPEED_OF_SOUND)
        put("first", i, "r2_gain1", min(0.95, opposite * d1 / d2))
        put("first", i, "r2_gain2", min(0.95, own * d2 / d3))

    for i, image in enumerate(SECOND_IMAGES):
        axes = [(axis, 1 if n > 0 else -1) for axis, n in enumerate(image) if n]
        d2 = distance(image)
        image4 = tuple(2 * n for n in image)
        d4 = distance(image4)
        initial_reflection = 1.0
        added_reflection = 1.0
        for axis, sign in axes:
            initial_reflection *= reflection[_wall_index(axis, sign)]
            added_reflection *= reflection[_wall_index(axis, -sign)]
        put("second", i, "delay_s", d2 / SPEED_OF_SOUND)
        put("second", i, "gain", _gain(d2, initial_reflection))
        put("second", i, "pan", _pan(_ray(image, room, source, listener), yaw_degrees, pitch_degrees))
        put("second", i, "r1_delay_s", (d4 - d2) / SPEED_OF_SOUND)
        put("second", i, "r1_gain", min(0.95, added_reflection * d2 / d4))

    if any(name.endswith("_s") and not 0 <= value <= MAX_DELAY_SECONDS
           for name, value in controls.items()):
        raise ValueError("a path exceeds the Faust delay capacity of 2 seconds")
    return controls


def send_touchdesigner_frame(osc_out_dat, **kwargs):
    """Send one coherent OSC bundle using a TouchDesigner OSC Out DAT."""
    frame = calculate_frame(**kwargs)
    arguments = []
    for address, value in frame.items():
        arguments.extend((address, [value]))
    osc_out_dat.sendOSC(*arguments, asBundle=True)
    return frame
