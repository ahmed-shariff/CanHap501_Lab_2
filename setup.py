import os
from pathlib import Path

def main():
    """Creates a symlink to all the `code` and `Pantograph.java` in all the subdirectories that have a pde file"""
    
    root_dir = Path(__file__).parent
    for pde_file in root_dir.glob("*/*.pde"):
        sketch_root = pde_file.parent
        print("Found pde file: {}".format(pde_file.relative_to(root_dir)))
        
        if (sketch_root / "code").exists():
            print("  `code` exists")
        else:
            print("  Symlink to `code`")
            os.symlink(root_dir / "code", sketch_root / "code")

        if (sketch_root / "Pantograph.java").exists():
            print("  `Pantograph.java` exists")
        else:
            print("  Symlink to `Pantograph.java`")
            os.symlink(root_dir / "Pantograph.java", sketch_root / "Pantograph.java")

if __name__=="__main__":
    main()
