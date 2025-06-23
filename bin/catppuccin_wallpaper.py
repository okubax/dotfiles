#!/usr/bin/env python3
"""
Catppuccin Wallpaper Generator
Generates beautiful tiled wallpapers using the Catppuccin color palette
"""

import random
import math
from PIL import Image, ImageDraw
import argparse

# Catppuccin color palettes
CATPPUCCIN_PALETTES = {
    'mocha': {
        'rosewater': '#f5e0dc',
        'flamingo': '#f2cdcd',
        'pink': '#f5c2e7',
        'mauve': '#cba6f7',
        'red': '#f38ba8',
        'maroon': '#eba0ac',
        'peach': '#fab387',
        'yellow': '#f9e2af',
        'green': '#a6e3a1',
        'teal': '#94e2d5',
        'sky': '#89dceb',
        'sapphire': '#74c7ec',
        'blue': '#89b4fa',
        'lavender': '#b4befe',
        'text': '#cdd6f4',
        'subtext1': '#bac2de',
        'subtext0': '#a6adc8',
        'overlay2': '#9399b2',
        'overlay1': '#7f849c',
        'overlay0': '#6c7086',
        'surface2': '#585b70',
        'surface1': '#45475a',
        'surface0': '#313244',
        'base': '#1e1e2e',
        'mantle': '#181825',
        'crust': '#11111b'
    },
    'macchiato': {
        'rosewater': '#f4dbd6',
        'flamingo': '#f0c6c6',
        'pink': '#f5bde6',
        'mauve': '#c6a0f6',
        'red': '#ed8796',
        'maroon': '#ee99a0',
        'peach': '#f5a97f',
        'yellow': '#eed49f',
        'green': '#a6da95',
        'teal': '#8bd5ca',
        'sky': '#91d7e3',
        'sapphire': '#7dc4e4',
        'blue': '#8aadf4',
        'lavender': '#b7bdf8',
        'text': '#cad3f5',
        'subtext1': '#b8c0e0',
        'subtext0': '#a5adcb',
        'overlay2': '#939ab7',
        'overlay1': '#8087a2',
        'overlay0': '#6e738d',
        'surface2': '#5b6078',
        'surface1': '#494d64',
        'surface0': '#363a4f',
        'base': '#24273a',
        'mantle': '#1e2030',
        'crust': '#181926'
    },
    'frappe': {
        'rosewater': '#f2d5cf',
        'flamingo': '#eebebe',
        'pink': '#f4b8e4',
        'mauve': '#ca9ee6',
        'red': '#e78284',
        'maroon': '#ea999c',
        'peach': '#ef9f76',
        'yellow': '#e5c890',
        'green': '#a6d189',
        'teal': '#81c8be',
        'sky': '#99d1db',
        'sapphire': '#85c1dc',
        'blue': '#8caaee',
        'lavender': '#babbf1',
        'text': '#c6d0f5',
        'subtext1': '#b5bfe2',
        'subtext0': '#a5adce',
        'overlay2': '#949cbb',
        'overlay1': '#838ba7',
        'overlay0': '#737994',
        'surface2': '#626880',
        'surface1': '#51576d',
        'surface0': '#414559',
        'base': '#303446',
        'mantle': '#292c3c',
        'crust': '#232634'
    },
    'latte': {
        'rosewater': '#dc8a78',
        'flamingo': '#dd7878',
        'pink': '#ea76cb',
        'mauve': '#8839ef',
        'red': '#d20f39',
        'maroon': '#e64553',
        'peach': '#fe640b',
        'yellow': '#df8e1d',
        'green': '#40a02b',
        'teal': '#179299',
        'sky': '#04a5e5',
        'sapphire': '#209fb5',
        'blue': '#1e66f5',
        'lavender': '#7287fd',
        'text': '#4c4f69',
        'subtext1': '#5c5f77',
        'subtext0': '#6c6f85',
        'overlay2': '#7c7f93',
        'overlay1': '#8c8fa1',
        'overlay0': '#9ca0b0',
        'surface2': '#acb0be',
        'surface1': '#bcc0cc',
        'surface0': '#ccd0da',
        'base': '#eff1f5',
        'mantle': '#e6e9ef',
        'crust': '#dce0e8'
    }
}

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def darken_color(rgb_color, factor=0.7):
    """Darken an RGB color by a given factor (0.0 = black, 1.0 = original)"""
    return tuple(int(c * factor) for c in rgb_color)

def draw_hexagon(draw, x, y, size, color):
    """Draw a hexagon at given position"""
    points = []
    for i in range(6):
        angle = math.pi / 3 * i
        px = x + size * math.cos(angle)
        py = y + size * math.sin(angle)
        points.append((px, py))
    draw.polygon(points, fill=color)

def generate_geometric_pattern(width, height, palette_name='mocha', pattern='hexagon', darkness=1.0):
    """Generate geometric tiled patterns"""
    palette = CATPPUCCIN_PALETTES[palette_name]
    img = Image.new('RGB', (width, height), hex_to_rgb(palette['base']))
    draw = ImageDraw.Draw(img)
    
    if pattern == 'hexagon':
        tile_size = 80
        colors = [palette['mauve'], palette['pink'], palette['blue'], palette['green'], palette['peach']]
        
        # Extend range to ensure full coverage
        for y in range(-tile_size, height + tile_size * 2, int(tile_size * 0.75)):
            for x in range(-tile_size, width + tile_size * 2, int(tile_size * 0.866)):
                # Offset every other row
                offset_x = (tile_size // 2) if (y // int(tile_size * 0.75)) % 2 else 0
                hex_x = x + offset_x
                
                color = random.choice(colors)
                final_color = darken_color(hex_to_rgb(color), darkness)
                draw_hexagon(draw, hex_x, y, tile_size // 2, final_color)
    
    elif pattern == 'triangle':
        tile_size = 60
        colors = [palette['lavender'], palette['sky'], palette['teal'], palette['yellow'], palette['red']]
        
        # Extend range to ensure full coverage
        for y in range(-tile_size, height + tile_size * 2, int(tile_size * 0.866)):
            for x in range(-tile_size, width + tile_size * 2, tile_size):
                color = random.choice(colors)
                # Upward triangle
                points = [(x, y + tile_size), (x + tile_size//2, y), (x + tile_size, y + tile_size)]
                draw.polygon(points, fill=darken_color(hex_to_rgb(color), darkness))
                
                # Downward triangle
                color2 = random.choice(colors)
                points2 = [(x + tile_size//2, y), (x + tile_size, y + tile_size), (x + tile_size + tile_size//2, y)]
                draw.polygon(points2, fill=darken_color(hex_to_rgb(color2), darkness))
    
    elif pattern == 'diamond':
        tile_size = 40
        colors = [palette['pink'], palette['mauve'], palette['blue'], palette['green']]
        
        # Extend range to ensure full coverage
        for y in range(-tile_size, height + tile_size * 2, tile_size):
            for x in range(-tile_size, width + tile_size * 2, tile_size):
                color = random.choice(colors)
                # Diamond shape
                points = [
                    (x + tile_size//2, y),
                    (x + tile_size, y + tile_size//2),
                    (x + tile_size//2, y + tile_size),
                    (x, y + tile_size//2)
                ]
                draw.polygon(points, fill=darken_color(hex_to_rgb(color), darkness))
    
    return img

def generate_gradient_waves(width, height, palette_name='mocha', darkness=1.0):
    """Generate flowing wave patterns with gradients"""
    palette = CATPPUCCIN_PALETTES[palette_name]
    img = Image.new('RGB', (width, height), hex_to_rgb(palette['base']))
    draw = ImageDraw.Draw(img)
    
    colors = [palette['mauve'], palette['pink'], palette['blue'], palette['lavender'], palette['sky']]
    
    for i in range(5):
        wave_height = height // 10
        y_offset = i * (height // 6)
        color = darken_color(hex_to_rgb(colors[i % len(colors)]), darkness)
        
        points = [(0, y_offset)]
        for x in range(0, width, 10):
            y = y_offset + wave_height * math.sin(x * 0.01 + i * 2)
            points.append((x, y))
        points.append((width, y_offset))
        points.append((width, height))
        points.append((0, height))
        
        draw.polygon(points, fill=color)
    
    return img

def generate_abstract_circles(width, height, palette_name='mocha', darkness=1.0):
    """Generate abstract overlapping circles"""
    palette = CATPPUCCIN_PALETTES[palette_name]
    img = Image.new('RGB', (width, height), hex_to_rgb(palette['base']))
    draw = ImageDraw.Draw(img)
    
    colors = [palette['pink'], palette['mauve'], palette['blue'], palette['green'], 
              palette['peach'], palette['yellow'], palette['teal']]
    
    # Generate random circles
    for _ in range(30):
        x = random.randint(-100, width + 100)
        y = random.randint(-100, height + 100)
        radius = random.randint(50, 200)
        color = darken_color(hex_to_rgb(random.choice(colors)), darkness)
        
        # Create semi-transparent effect by blending
        overlay = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        overlay_draw.ellipse([x-radius, y-radius, x+radius, y+radius], 
                           fill=(*color, 100))  # Semi-transparent
        
        img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    
    return img

def generate_pixel_noise(width, height, palette_name='mocha', darkness=1.0):
    """Generate organized pixel noise pattern"""
    palette = CATPPUCCIN_PALETTES[palette_name]
    img = Image.new('RGB', (width, height), hex_to_rgb(palette['base']))
    
    colors = [palette['pink'], palette['mauve'], palette['blue'], palette['green'], 
              palette['peach'], palette['yellow'], palette['teal'], palette['lavender']]
    
    pixel_size = 8
    for y in range(0, height, pixel_size):
        for x in range(0, width, pixel_size):
            if random.random() > 0.7:  # 30% chance for colored pixel
                color = darken_color(hex_to_rgb(random.choice(colors)), darkness)
                for py in range(pixel_size):
                    for px in range(pixel_size):
                        if x + px < width and y + py < height:
                            img.putpixel((x + px, y + py), color)
    
    return img

def generate_plain_background(width, height, palette_name='mocha', color_name='base', darkness=1.0):
    """Generate plain solid color background"""
    palette = CATPPUCCIN_PALETTES[palette_name]
    
    if color_name not in palette:
        print(f"Warning: Color '{color_name}' not found in {palette_name} palette. Using 'base' instead.")
        color_name = 'base'
    
    color = darken_color(hex_to_rgb(palette[color_name]), darkness)
    img = Image.new('RGB', (width, height), color)
    return img

def generate_gradient_background(width, height, palette_name='mocha', color1='base', color2='surface0', direction='horizontal', darkness=1.0):
    """Generate gradient background between two colors"""
    palette = CATPPUCCIN_PALETTES[palette_name]
    
    # Validate colors
    if color1 not in palette:
        print(f"Warning: Color '{color1}' not found in {palette_name} palette. Using 'base' instead.")
        color1 = 'base'
    if color2 not in palette:
        print(f"Warning: Color '{color2}' not found in {palette_name} palette. Using 'surface0' instead.")
        color2 = 'surface0'
    
    # Get RGB values and apply darkness
    rgb1 = darken_color(hex_to_rgb(palette[color1]), darkness)
    rgb2 = darken_color(hex_to_rgb(palette[color2]), darkness)
    
    img = Image.new('RGB', (width, height))
    
    if direction == 'horizontal':
        # Horizontal gradient (left to right)
        for x in range(width):
            ratio = x / width
            r = int(rgb1[0] * (1 - ratio) + rgb2[0] * ratio)
            g = int(rgb1[1] * (1 - ratio) + rgb2[1] * ratio)
            b = int(rgb1[2] * (1 - ratio) + rgb2[2] * ratio)
            
            for y in range(height):
                img.putpixel((x, y), (r, g, b))
    
    elif direction == 'vertical':
        # Vertical gradient (top to bottom)
        for y in range(height):
            ratio = y / height
            r = int(rgb1[0] * (1 - ratio) + rgb2[0] * ratio)
            g = int(rgb1[1] * (1 - ratio) + rgb2[1] * ratio)
            b = int(rgb1[2] * (1 - ratio) + rgb2[2] * ratio)
            
            for x in range(width):
                img.putpixel((x, y), (r, g, b))
    
    elif direction == 'diagonal':
        # Diagonal gradient (top-left to bottom-right)
        max_distance = math.sqrt(width**2 + height**2)
        for y in range(height):
            for x in range(width):
                distance = math.sqrt(x**2 + y**2)
                ratio = distance / max_distance
                r = int(rgb1[0] * (1 - ratio) + rgb2[0] * ratio)
                g = int(rgb1[1] * (1 - ratio) + rgb2[1] * ratio)
                b = int(rgb1[2] * (1 - ratio) + rgb2[2] * ratio)
                img.putpixel((x, y), (r, g, b))
    
    elif direction == 'radial':
        # Radial gradient (center outward)
        center_x, center_y = width // 2, height // 2
        max_distance = math.sqrt(center_x**2 + center_y**2)
        
        for y in range(height):
            for x in range(width):
                distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
                ratio = min(distance / max_distance, 1.0)
                r = int(rgb1[0] * (1 - ratio) + rgb2[0] * ratio)
                g = int(rgb1[1] * (1 - ratio) + rgb2[1] * ratio)
                b = int(rgb1[2] * (1 - ratio) + rgb2[2] * ratio)
                img.putpixel((x, y), (r, g, b))
    
    return img

def add_text_overlay(img, text, palette_name='mocha', text_color='text', font_size=None):
    """Add text overlay to the center of the image"""
    if not text.strip():
        return img
    
    palette = CATPPUCCIN_PALETTES[palette_name]
    
    # Validate text color
    if text_color not in palette:
        print(f"Warning: Text color '{text_color}' not found in {palette_name} palette. Using 'text' instead.")
        text_color = 'text'
    
    width, height = img.size
    draw = ImageDraw.Draw(img)
    
    # Auto-calculate font size if not provided
    if font_size is None:
        font_size = max(24, min(width, height) // 20)
    
    try:
        # Try to use a system font
        import platform
        system = platform.system()
        
        if system == "Linux":
            # Common font paths on Linux
            font_paths = [
                "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                "/usr/share/fonts/TTF/liberation/LiberationSans-Bold.ttf",
                "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
                "/usr/share/fonts/noto/NotoSans-Bold.ttf",
                "/usr/share/fonts/google-noto/NotoSans-Bold.ttf"
            ]
            
            font = None
            for font_path in font_paths:
                try:
                    from PIL import ImageFont
                    font = ImageFont.truetype(font_path, font_size)
                    break
                except:
                    continue
            
            if font is None:
                font = ImageFont.load_default()
        else:
            font = ImageFont.load_default()
            
    except ImportError:
        # Fallback to default font
        try:
            font = ImageFont.load_default()
        except:
            # If all else fails, use basic drawing
            pass
    
    # Get text color
    text_rgb = hex_to_rgb(palette[text_color])
    
    # Get text bounding box
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
    except:
        # Fallback for older Pillow versions
        text_width, text_height = draw.textsize(text, font=font)
    
    # Calculate centered position
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    # Draw text with slight shadow for better visibility
    shadow_offset = max(1, font_size // 24)
    shadow_color = (0, 0, 0) if palette_name == 'latte' else (255, 255, 255)
    
    # Draw shadow
    draw.text((x + shadow_offset, y + shadow_offset), text, font=font, fill=shadow_color)
    # Draw main text
    draw.text((x, y), text, font=font, fill=text_rgb)
    
    return img

def generate_random_wallpaper(width, height):
    """Generate a completely random wallpaper with random settings"""
    # Random palette
    palette_name = random.choice(['mocha', 'macchiato', 'frappe', 'latte'])
    palette = CATPPUCCIN_PALETTES[palette_name]
    
    # Random pattern
    pattern = random.choice(['hexagon', 'triangle', 'diamond', 'waves', 'circles', 'noise', 'plain', 'gradient'])
    
    # Random darkness (biased towards usable ranges)
    darkness_options = [1.0, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1]
    darkness = random.choice(darkness_options)
    
    # All available colors
    all_colors = list(palette.keys())
    
    # Generate random colors for gradients
    color1 = random.choice(all_colors)
    color2 = random.choice(all_colors)
    
    # Random gradient direction
    direction = random.choice(['horizontal', 'vertical', 'diagonal', 'radial'])
    
    # Random text (30% chance)
    text_options = ['', '', '', '~', 'λ', '◆', '⬢', '△', '◯', 'Arch', 'Linux', 'Hello', 'Code', '✦', '⟡']
    text = random.choice(text_options)
    
    # Random text color
    text_color = random.choice(all_colors)
    
    # Random font size (if text is chosen)
    font_size = random.randint(32, 120) if text else None
    
    print(f"🎲 Random wallpaper settings:")
    print(f"   Palette: {palette_name}")
    print(f"   Pattern: {pattern}")
    print(f"   Darkness: {darkness}")
    
    if pattern == 'gradient':
        print(f"   Colors: {color1} → {color2}")
        print(f"   Direction: {direction}")
        img = generate_gradient_background(width, height, palette_name, color1, color2, direction, darkness)
    elif pattern == 'plain':
        color = random.choice(all_colors)
        print(f"   Color: {color}")
        img = generate_plain_background(width, height, palette_name, color, darkness)
    else:
        print(f"   Pattern: {pattern}")
        if pattern in ['hexagon', 'triangle', 'diamond']:
            img = generate_geometric_pattern(width, height, palette_name, pattern, darkness)
        elif pattern == 'waves':
            img = generate_gradient_waves(width, height, palette_name, darkness)
        elif pattern == 'circles':
            img = generate_abstract_circles(width, height, palette_name, darkness)
        elif pattern == 'noise':
            img = generate_pixel_noise(width, height, palette_name, darkness)
    
    # Add random text if chosen
    if text:
        print(f"   Text: '{text}' (color: {text_color}, size: {font_size})")
        img = add_text_overlay(img, text, palette_name, text_color, font_size)
    else:
        print(f"   Text: None")
    
    return img

def main():
    # Get all available colors from any palette (they're consistent across palettes)
    available_colors = list(CATPPUCCIN_PALETTES['mocha'].keys())
    color_help = f"Color name for plain backgrounds. Available colors: {', '.join(available_colors)}"
    color1_help = f"First color for gradient backgrounds. Available colors: {', '.join(available_colors)}"
    color2_help = f"Second color for gradient backgrounds. Available colors: {', '.join(available_colors)}"
    text_color_help = f"Color for text overlay. Available colors: {', '.join(available_colors)}"
    
    parser = argparse.ArgumentParser(
        description='Generate beautiful Catppuccin wallpapers with various patterns, gradients, and text overlays',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Available Catppuccin Colors:
  Background colors: base, mantle, crust, surface0, surface1, surface2
  Text colors: text, subtext1, subtext0, overlay2, overlay1, overlay0
  Accent colors: rosewater, flamingo, pink, mauve, red, maroon, peach, 
                yellow, green, teal, sky, sapphire, blue, lavender

Pattern Examples:
  Basic geometric: --pattern hexagon --darkness 0.3
  Gradient: --pattern gradient --color1 base --color2 mauve --direction radial
  With text: --pattern plain --color base --text "Arch Linux" --text-color pink
  Dark variant: --pattern waves --darkness 0.2 --palette mocha

Gradient Directions:
  horizontal: Left to right gradient
  vertical: Top to bottom gradient  
  diagonal: Top-left to bottom-right gradient
  radial: Circular gradient from center outward

Darkness Examples:
  --darkness 1.0: Normal brightness (default)
  --darkness 0.7: Slightly darker
  --darkness 0.3: Very dark
  --darkness 0.1: Ultra-dark (subtle colors)

Random Examples:
  catppuccin_wallpaper.py --random
  catppuccin_wallpaper.py --random --width 1920 --height 1080 --output surprise.png
  
  # Generate 5 random wallpapers
  for i in {{1..5}}; do catppuccin_wallpaper.py --random --output random_$i.png; done

Complete Examples:
  catppuccin_wallpaper.py --width 2560 --height 1600 --pattern gradient \\
    --color1 rosewater --color2 teal --direction radial --darkness 0.3 \\
    --text "Hello World" --text-color lavender --output beautiful.png
        """)
    
    parser.add_argument('--width', type=int, default=2560, help='Width of wallpaper (default: 2560)')
    parser.add_argument('--height', type=int, default=1600, help='Height of wallpaper (default: 1600)')
    parser.add_argument('--palette', choices=['mocha', 'macchiato', 'frappe', 'latte'], 
                       default='mocha', help='Catppuccin palette to use (default: mocha)')
    parser.add_argument('--pattern', choices=['hexagon', 'triangle', 'diamond', 'waves', 'circles', 'noise', 'plain', 'gradient'], 
                       default='hexagon', help='Pattern type (default: hexagon)')
    parser.add_argument('--color', default='base', help=color_help)
    parser.add_argument('--color1', default='base', help=color1_help)
    parser.add_argument('--color2', default='surface0', help=color2_help)
    parser.add_argument('--direction', choices=['horizontal', 'vertical', 'diagonal', 'radial'], 
                       default='horizontal', help='Gradient direction (default: horizontal)')
    parser.add_argument('--text', default='', help='Text to overlay on the image (centered)')
    parser.add_argument('--text-color', default='text', help=text_color_help)
    parser.add_argument('--font-size', type=int, default=None, 
                       help='Font size for text (auto-calculated based on image size if not specified)')
    parser.add_argument('--darkness', type=float, default=1.0, 
                       help='Darkness factor: 0.1=very dark, 1.0=normal brightness (default: 1.0)')
    parser.add_argument('--random', action='store_true', 
                       help='Generate completely random wallpaper (ignores most other options)')
    parser.add_argument('--output', default='catppuccin_wallpaper.png', 
                       help='Output filename (default: catppuccin_wallpaper.png)')
    
    args = parser.parse_args()
    
    if args.random:
        print("🎨 Generating random wallpaper...")
        img = generate_random_wallpaper(args.width, args.height)
    else:
        print(f"Generating {args.width}x{args.height} wallpaper with {args.palette} palette...")
        
        if args.pattern in ['hexagon', 'triangle', 'diamond']:
            img = generate_geometric_pattern(args.width, args.height, args.palette, args.pattern, args.darkness)
        elif args.pattern == 'waves':
            img = generate_gradient_waves(args.width, args.height, args.palette, args.darkness)
        elif args.pattern == 'circles':
            img = generate_abstract_circles(args.width, args.height, args.palette, args.darkness)
        elif args.pattern == 'noise':
            img = generate_pixel_noise(args.width, args.height, args.palette, args.darkness)
        elif args.pattern == 'plain':
            img = generate_plain_background(args.width, args.height, args.palette, args.color, args.darkness)
        elif args.pattern == 'gradient':
            img = generate_gradient_background(args.width, args.height, args.palette, args.color1, args.color2, args.direction, args.darkness)
        
        # Add text overlay if specified
        if args.text:
            img = add_text_overlay(img, args.text, args.palette, args.text_color, args.font_size)
    
    img.save(args.output, 'PNG', optimize=True)
    print(f"Wallpaper saved as {args.output}")

if __name__ == "__main__":
    main()
