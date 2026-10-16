extends RefCounted

# Short numbers for scores so they never overflow: 9999, 75.3K, 253K, 1.25M, 2.5B

const UNITS := [[1000000000.0, "B"], [1000000.0, "M"], [1000.0, "K"]]
const FULL_BELOW := 10000  # smaller numbers are shown in full

static func compact(value: int) -> String:
	if absi(value) < FULL_BELOW:
		return str(value)
	for unit in UNITS:
		if absi(value) >= unit[0]:
			var amount = value / unit[0]
			# 3 significant digits, cut down (not rounded) so 999,999 shows 999K and not 1000K
			var decimals = 2 if absf(amount) < 10.0 else (1 if absf(amount) < 100.0 else 0)
			var factor = pow(10.0, decimals)
			amount = floorf(amount * factor) / factor
			var text = ("%." + str(decimals) + "f") % amount
			if decimals > 0:
				text = text.rstrip("0").rstrip(".")  # 75.0K -> 75K
			return text + unit[1]
	return str(value)
