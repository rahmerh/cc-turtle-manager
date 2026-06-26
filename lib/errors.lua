local errors = {
    NIL_PARAM = "nil_param",
    INVALID_PARAM = "invalid_param",

    NO_FUEL = "no_fuel",
    NO_FUEL_STORED = "no_fuel_stored",
    NOT_FUEL = "not_fuel",

    BLOCKED = "blocked",
    INVALID_DIRECTION = "invalid_direction",
    NO_INVENTORY_DOWN = "no_inv_down",
    NO_GPS = "no_gps",

    INV_FULL = "inv_full",
    SLOT_EMPTY = "slot_empty",
    SLOT_NOT_EMPTY = "slot_not_empty",
    ITEM_UNAVAILABLE = "item_unavailable",

    NO_MONITOR_ATTACHED = "no_monitor_attached",
    INVALID_MONITOR = "invalid_monitor",
    INVALID_ELEMENT = "invalid_element",

    wireless = {
        NO_ACK = "wireless:no_ack",
        TIMEOUT = "wireless:timeout",
        COULD_NOT_ASSIGN = "wireless:could_not_assign",
        INVALID_RESPONSE_MESSAGE = "wireless:invalid_response_message",
        NO_AVAILABLE_RUNNERS = "wireless:no_available_runners",
    }
}

return errors
