# mpv-dji-osmo-360

Play proprietary **DJI Osmo 360** (`.osv`) video files natively in interactive 360° spherical projection on Linux (with NVIDIA GPU) with zero lag and perfect audio-video synchronization.

---

## The Challenge

DJI Osmo 360 `.osv` files are standard containers containing **two separate video tracks** (front and back lenses), each encoded at a massive resolution of **`3840x3840 @ 50 FPS`** in 10-bit HEVC. 

Playing them interactively requires:
1. Decoding both high-resolution streams simultaneously.
2. Stitching them side-by-side on-the-fly.
3. Rendering them using a spherical shader in real time.

Standard video players only decode one track at a time. Using CPU-based filtergraphs (like `hstack`) forces `mpv` to copy raw video frames back to system memory (RAM) over PCIe at a staggering rate of **4.4 Gigabytes per second**, overloading the CPU and causing severe desync and lag.

## The Solution

This project solves this bottleneck with a **100% GPU-bound pipeline**:

1. **GPU-Accelerated Stitching**: A background `ffmpeg` process decodes both tracks natively on the GPU using NVIDIA NVDEC, scales, pads, and overlays them side-by-side entirely in VRAM using CUDA hardware filters (`scale_cuda`, `pad_cuda`, `overlay_cuda`), and compresses the output on-the-fly using the hardware encoder (`hevc_nvenc`) at visually lossless quality (`qp 22`).
2. **Growing File Playback**: The stitched stream is written in real time to a temporary growing MPEG-TS (`.ts`) file, which is opened natively by `mpv`. This eliminates pipe-level synchronization issues, allowing **native, fluid backward and forward seeking** using `mpv`'s memory cache.
3. **Dynamic Shaders**: We modified the `mpv360` GLSL shader to convert camera coordinates (`yaw`, `pitch`, `fov`) from Vulkan specialization constants into `DYNAMIC` uniforms. This prevents `libplacebo` / `gpu-next` from invalidating rendering pipelines and re-allocating textures on every mouse movement.

---

## Features

- **No Pre-conversion**: Start watching your DJI `.osv` files in under a second.
- **Pristine Quality**: Visually lossless 7.6K ($7680 \times 3840$) stitching at native 50 FPS.
- **Interactive 360° Navigation**: Click-and-drag with the mouse to look around, use the scroll wheel to zoom.
- **Fluid Seeking**: Jump forward and backward in the video timeline without rendering artifacts or stream crashes.
- **Performance Presets**: Lower-resolution presets for older hardware or lower-spec GPUs.

---

## Requirements

- **OS**: Linux (tested on Arch Linux).
- **GPU**: NVIDIA GPU with proprietary drivers (tested on RTX 5080).
- **Packages**:
  - `mpv` (compiled with `--vo=gpu-next` and `--hwdec=nvdec`).
  - `ffmpeg` (compiled with CUDA filters `scale_cuda`, `pad_cuda`, `overlay_cuda` and the `hevc_nvenc` encoder).

---

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mpv-dji-osmo-360.git
   cd mpv-dji-osmo-360
   ```

2. Run the configurator script:
   ```bash
   ./setup_dji_360.sh
   ```

3. Ensure your local binary directory is in your `PATH`. If it isn't already, add this line to your `~/.bashrc` or `~/.zshrc`:
   ```bash
   export PATH=$PATH:$HOME/.local/bin
   ```

---

## Usage

Simply play your video files using the wrapper script:

```bash
dji-play-360 percorso/del/video.osv
```

### Performance Presets
If your GPU is struggling at full 7.6K resolution, you can downscale the lenses on the fly:
* **`--fast`**: Resizes each lens to 1.4K (total output $2880 \times 1440$).
* **`--fastest`**: Resizes each lens to 1K (total output $2048 \times 1024$).

```bash
dji-play-360 video.osv --fastest
```

---

## Controls

During playback, you can control the view using your mouse and keyboard:

* **Mouse Look**: Hold `Ctrl` + `Left Click` and drag the mouse to rotate the camera. Press `ESC` or `Ctrl` + `Click` again to exit mouse look.
* **Zoom (FOV)**: Scroll the mouse wheel up/down (or use `Ctrl` + `Shift` + `Up`/`Down`) to zoom in and out.
* **Reset View**: Press `Ctrl` + `r` to reset the camera to the default orientation.
* **Help Menu**: Press `Ctrl` + `t` to show the full list of controls on the OSD.

---

## Project Structure

- `bin/dji-play-360`: Real-time GPU transcoding and playback wrapper script.
- `scripts/mpv360.lua`: Lua script managing player inputs and camera parameters updates.
- `shaders/mpv360.glsl`: GLSL shader doing spherical projection mapping and dual-fisheye stitching.
- `script-opts/mpv360.conf`: Custom keybindings mapping for interactive 360° navigation.
- `setup_dji_360.sh`: Automatic installer script.

---

## License

This project is licensed under the MIT License. Shader and Lua script logic adapted from the original `mpv360` project by Kacper Michajłow.
