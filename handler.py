import os
import zipfile
import torch
import uuid
import tempfile
import requests
import numpy as np
import trimesh
import base64

from huggingface_hub import hf_hub_download
from triposg.pipelines.pipeline_triposg import TripoSGPipeline
from briarmbg import BriaRMBG
from inference_triposg import run_triposg


class EndpointHandler:
    def __init__(self, path=""):
        # Выбор устройства
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.dtype = torch.float16 if self.device == "cuda" else torch.float32

        # Папка с весами
        self.weights_dir = "pretrained_weights"
        self.triposg_path = os.path.join(self.weights_dir, "TripoSG")
        self.rmbg_path = os.path.join(self.weights_dir, "RMBG-1.4")

        # Скачиваем и распаковываем веса, если нужно
        if not (os.path.exists(self.triposg_path) and os.path.exists(self.rmbg_path)):
            print("📦 Downloading pretrained weights...")
            zip_file = hf_hub_download(
                repo_id="endlesstools/pretrained-assets",
                filename="pretrained_models.zip",
                repo_type="dataset"
            )

            with zipfile.ZipFile(zip_file, "r") as zip_ref:
                zip_ref.extractall(self.weights_dir)
            print("✅ Weights ready.")

        # Загружаем пайплайны
        self.pipe = TripoSGPipeline.from_pretrained(self.triposg_path).to(self.device, self.dtype)
        self.rmbg_net = BriaRMBG.from_pretrained(self.rmbg_path).to(self.device)
        self.rmbg_net.eval()


    def __call__(self, data):
        inputs = data.get("inputs", [])
        if not inputs or not isinstance(inputs, list) or len(inputs) == 0:
            return {"error": "No inputs provided"}

        try:
            image_b64 = inputs[0]
            face_number = round(float(inputs[1])) if len(inputs) > 1 else 50000
            guidance_scale = float(inputs[2]) if len(inputs) > 2 else 20.0 # default 2 - 5 / 7–12 - хороший баланс  / 12–16 максимальное соответствие // >16 может все ломать 
            num_steps = round(float(inputs[3])) if len(inputs) > 3 else 100  # default 3 - 25 / 50–100 - хороший баланс / 100–200 для сложных сцен
            octree_depth = round(float(inputs[4])) if len(inputs) > 4 else 9

           
            image_bytes = base64.b64decode(image_b64.split(",")[-1])

            with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as tmp_img:
                tmp_img.write(image_bytes)
                tmp_img_path = tmp_img.name

            mesh = run_triposg(
                pipe=self.pipe,
                image_input=tmp_img_path,
                rmbg_net=self.rmbg_net,
                seed=42,
                num_inference_steps=num_steps,
                guidance_scale=guidance_scale,
                faces=face_number,
                octree_depth=octree_depth
            )

            if mesh is None or mesh.vertices.shape[0] == 0 or mesh.faces.shape[0] == 0:
              raise ValueError("Mesh generation returned an empty mesh")

            import trimesh.repair

            # Создаём чистый Trimesh и нормализуем
            mesh = trimesh.Trimesh(vertices=mesh.vertices, faces=mesh.faces, process=False)

            mesh.apply_translation(-mesh.center_mass)
            scale_factor = 1.0 / np.max(np.linalg.norm(mesh.vertices, axis=1))
            mesh.apply_scale(scale_factor)

            # Пересчёт нормалей
            mesh.face_normals = mesh.face_normals  # пересчёт
            mesh.vertex_normals = mesh.vertex_normals  # пересчёт
            trimesh.repair.fix_normals(mesh)
            
            # add UV mapping if not present unwrap_uv
            # if mesh.visual.uv is None or len(mesh.visual.uv) == 0:
            #     print("[INFO] UV unwrap: generating basic UV map")
            #     try:
            #         mesh.visual.uv = trimesh.mapping.uv.unwrap_uv(mesh)
            #     except Exception as unwrap_error:
            #         print("[WARNING] UV unwrap failed:", unwrap_error)

            print("[DEBUG] Final normals shape:", mesh.vertex_normals.shape)

            # Экспорт
            glb_data = mesh.export(file_type='glb')
            glb_b64 = base64.b64encode(glb_data).decode("utf-8")

            return {"glb": glb_b64}

        except Exception as e:
            return {"error": str(e)}