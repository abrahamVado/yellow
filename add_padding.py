from PIL import Image
import os

def add_padding(input_path, output_path, padding_ratio=0.3, background_color=(0, 0, 0)):
    try:
        img = Image.open(input_path)
        original_width, original_height = img.size
        
        # Calculate new size (keeping aspect ratio)
        # We want the original image to be (1 - padding_ratio) of the canvas
        # So if padding_ratio is 0.3 (30%), the image will be 70% of the canvas
        scale_factor = 1.0 - padding_ratio
        new_width = int(original_width * scale_factor)
        new_height = int(original_height * scale_factor)
        
        # Resize the image
        img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create new background
        background = Image.new('RGB', (original_width, original_height), background_color)
        
        # Calculate position to center
        x_offset = (original_width - new_width) // 2
        y_offset = (original_height - new_height) // 2
        
        # Paste resized image onto background
        background.paste(img_resized, (x_offset, y_offset))
        
        # Save
        background.save(output_path, quality=95)
        print(f"Successfully created padded icon at {output_path}")
        
    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    input_file = "assets/icon.jpeg"
    output_file = "assets/icon_padded.jpeg"
    
    if os.path.exists(input_file):
        add_padding(input_file, output_file)
    else:
        print(f"Input file not found: {input_file}")
