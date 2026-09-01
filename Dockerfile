# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""
ARG CIVITAI_API_KEY=""

# install custom nodes into comfyui
RUN git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy && cd /comfyui/custom_nodes/rgthree-comfy && (git checkout 683836c46e898668936c433502504cc0627482c5 2>/dev/null || (git fetch origin 683836c46e898668936c433502504cc0627482c5 --depth=1 && git checkout 683836c46e898668936c433502504cc0627482c5) || echo "WARN: commit 683836c46e898668936c433502504cc0627482c5 unreachable in https://github.com/rgthree/rgthree-comfy, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail comfyui_controlnet_aux@1.1.3 --mode remote || (echo "WARN: comfyui_controlnet_aux@1.1.3 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui_controlnet_aux --mode remote)
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use /comfyui/custom_nodes/ComfyUI-Easy-Use && cd /comfyui/custom_nodes/ComfyUI-Easy-Use && (git checkout 3e84b8cd77719341adc71b08b5789bdb07b1a543 2>/dev/null || (git fetch origin 3e84b8cd77719341adc71b08b5789bdb07b1a543 --depth=1 && git checkout 3e84b8cd77719341adc71b08b5789bdb07b1a543) || echo "WARN: commit 3e84b8cd77719341adc71b08b5789bdb07b1a543 unreachable in https://github.com/yolain/ComfyUI-Easy-Use, falling back to default branch HEAD")
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale /comfyui/custom_nodes/ComfyUI_UltimateSDUpscale && cd /comfyui/custom_nodes/ComfyUI_UltimateSDUpscale && (git checkout 627c871f14532b164331f08d0eebfbf7404161ee 2>/dev/null || (git fetch origin 627c871f14532b164331f08d0eebfbf7404161ee --depth=1 && git checkout 627c871f14532b164331f08d0eebfbf7404161ee) || echo "WARN: commit 627c871f14532b164331f08d0eebfbf7404161ee unreachable in https://github.com/ssitu/ComfyUI_UltimateSDUpscale, falling back to default branch HEAD")
RUN git clone https://github.com/cyberdeliaAI/comfyui-cyberdelia-metadata /comfyui/custom_nodes/comfyui-cyberdelia-metadata && cd /comfyui/custom_nodes/comfyui-cyberdelia-metadata && (git checkout ed58201eb1cc8d9fbd53bbd93d4d89549f982bb4 2>/dev/null || (git fetch origin ed58201eb1cc8d9fbd53bbd93d4d89549f982bb4 --depth=1 && git checkout ed58201eb1cc8d9fbd53bbd93d4d89549f982bb4) || echo "WARN: commit ed58201eb1cc8d9fbd53bbd93d4d89549f982bb4 unreachable in https://github.com/cyberdeliaAI/comfyui-cyberdelia-metadata, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail comfyui-impact-subpack@1.3.5 || (echo "WARN: comfyui-impact-subpack@1.3.5 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-impact-subpack)
RUN comfy node install --exit-on-fail comfyui-impact-pack@8.28.2 || (echo "WARN: comfyui-impact-pack@8.28.2 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-impact-pack)

# download models into comfyui
RUN BACKOFFS="60 300 900 1800 3600" && for i in 1 2 3 4 5; do CIVITAI_API_KEY=$CIVITAI_API_KEY comfy model download --url 'https://civitai.com/api/download/models/2962407?fileId=2841803' --relative-path models/checkpoints --filename 'CyberIllustrious_Anime_V6.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/xinsir/controlnet-union-sdxl-1.0/resolve/main/diffusion_pytorch_model_promax.safetensors' --relative-path models/controlnet --filename 'diffusion_pytorch_model_promax.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/nateraw/real-esrgan/resolve/44ad8adf6069185b86df22349b12f255821c86ab/RealESRGAN_x4plus_anime_6B.pth' --relative-path models/upscale_models --filename 'RealESRGAN_x4plus_anime_6B.pth' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt' --relative-path models/ultralytics --filename 'bbox/face_yolov8m.pt' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/example.png' "https://cool-anteater-319.convex.cloud/api/storage/25b2c434-d7e4-4cf9-8a40-8f4b9f4ec566"
