import re

file_path = '/Users/michael/Documents/iPhone/rubik/lib/models/alg_library.dart'

with open(file_path, 'r') as f:
    content = f.read()

replacements = {
    "'Aa-perm'": "'Aa-perm\\n(3 Corners CCW)'",
    "'Ab-perm'": "'Ab-perm\\n(3 Corners CW)'",
    "'E-perm'": "'E-perm\\n(Diagonal Corners)'",
    "'Ua-perm'": "'Ua-perm\\n(3 Edges CCW)'",
    "'Ub-perm'": "'Ub-perm\\n(3 Edges CW)'",
    "'Z-perm'": "'Z-perm\\n(Adjacent Edges)'",
    "'H-perm'": "'H-perm\\n(Opposite Edges)'",
    "'Ja-perm'": "'Ja-perm\\n(Adj. Swap L)'",
    "'Jb-perm'": "'Jb-perm\\n(Adj. Swap R)'",
    "'T-perm'": "'T-perm\\n(Adjacent Swap)'",
    "'F-perm'": "'F-perm\\n(Adj Swap, Opp Edge)'",
    "'Y-perm'": "'Y-perm\\n(Diagonal Swap)'",
    "'V-perm'": "'V-perm\\n(Diag. Swap, Adj Edges)'",
    "'Ga-perm'": "'Ga-perm\\n(G-Cycle A)'",
    "'Gb-perm'": "'Gb-perm\\n(G-Cycle B)'",
    "'Gc-perm'": "'Gc-perm\\n(G-Cycle C)'",
    "'Gd-perm'": "'Gd-perm\\n(G-Cycle D)'",
    "'Ra-perm'": "'Ra-perm\\n(R-Cycle A)'",
    "'Rb-perm'": "'Rb-perm\\n(R-Cycle B)'",
    "'Na-perm'": "'Na-perm\\n(Diag. Swap A)'",
    "'Nb-perm'": "'Nb-perm\\n(Diag. Swap B)'",
}

def replace_name(match):
    name = match.group(1)
    if name in replacements:
        return f"name: {replacements[name]},"
    return match.group(0)

new_content = re.sub(r'name:\s*(\'[^\']+\'),', replace_name, content)

with open(file_path, 'w') as f:
    f.write(new_content)

print("Done updating alg_library.dart")
