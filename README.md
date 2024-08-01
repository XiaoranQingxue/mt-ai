# MT-AI
## 本仓库仅为个人学习交流使用，如作他用所承受的法律责任一概与作者无关（下载使用即代表你同意上述观点）

使用immich开源的人脸及clip，供个人mt-photos使用


### docker ENV 说明

| ENV | 含义 | 默认值|
| ---- | ---- | ----|
| FACE_MODEL_NAME | 人脸识别模型 | antelopev2 |
| CLIP_MODEL_NAME | CLIP模型| XLM-Roberta-Large-Vit-B-16Plus |
| FACE_THRESHOLD | 人脸置信度 | 0.7 |
| MODEL_TTL | 模型卸载间隔(s) | 0 |
| LOG_LEVEL | 日志等级 | ERROR |

**mtphotos中，人脸置信度建议修改为~~0.7~~0.55，人物匹配差异值建议修改为~~0.5~~0.35左右！**
### 脚本说明
- 确保已成功配置docker服务
- 请在root权限执行
- 通过`docker ps` 获取正在运行的mt-photos镜像ID
- 参数说明：1. 容器ID， 2. clip服务地址 3. 向量长度，默认640 请按选择的clip模型正确修改
- 执行 `./up-im-clip.sh <your-container-name> <clip-server-ip port> <vec_length -640>`(P: `./up-im-clip.sh 1387079e86ad 192.168.3.4:3003 640`)


### 实例compose.yaml
```
version: "3"

services:
  mtphotos:
    image: mtphotos/mt-photos:latest
    container_name: mtphotos
    restart: always
    ports:
      - 8063:8063
    volumes:
      - /volume1/docker/mtphotos/config:/config
      - /volume1/docker/mtphotos/upload:/upload
      - /volume1/photo:/photos
    environment:
      - TZ=Asia/Shanghai
      - LANG=C.UTF-8
    depends_on:
      - mtphotos_ai
  mtphotos_ai:
    image: ghcr.io/xiaoranqingxue/mt-ai-cpu:latest
    container_name: mt-ai-cpu
    restart: always
    ports:
      - 3003:3003
    volumes:
      - /volume1/docker/immich/model-cache:/cache
    environment:
      - API_AUTH_KEY=mt_photos_ai_extra
      - FACE_MODEL_NAME=buffalo_l # antelopev2
      - CLIP_MODEL_NAME=XLM-Roberta-Large-Vit-B-16Plus
      - FACE_THRESHOLD=0.7
      - MODEL_TTL=0
      - LOG_LEVEL=ERROR

```
### 实例compose.yaml (iGPU)
```
version: "3"

services:
  mtphotos:
    image: mtphotos/mt-photos:latest
    container_name: mtphotos
    restart: always

    ports:
      - 8063:8063
    volumes:
      - /volume1/docker/mtphotos/config:/config
      - /volume1/docker/mtphotos/upload:/upload
      - /volume1/photo:/photos
      # 个人文件夹路径
    environment:
      - TZ=Asia/Shanghai
      - LANG=C.UTF-8
    depends_on:
      - mtphotos_ai
  mtphotos_ai:
    image: ghcr.io/xiaoranqingxue/mt-ai-openvino:latest
    container_name: mt-ai-openvino
    device_cgroup_rules:
      - 'c 189:* rmw'
    devices:
      - /dev/dri:/dev/dri
    restart: always

    ports:
      - 3003:3003
    volumes:
      - /dev/bus/usb:/dev/bus/usb
      - /volume1/docker/immich/model-cache:/cache
    environment:
      - DEVICE=/dev/dri/renderD128
      - API_AUTH_KEY=mt_photos_ai_extra
      - FACE_MODEL_NAME=antelopev2 # antelopev2,buffalo_l
      - CLIP_MODEL_NAME=XLM-Roberta-Large-Vit-B-16Plus #nllb-clip-base-siglip__mrl #XLM-Roberta-Large-Vit-B-16Plus
      - FACE_THRESHOLD=0.45
      - MODEL_TTL=300
      - LOG_LEVEL=ERROR

```

### v0.9
修复clip/img返回结果中出现的以科学计数法存在的数字

### v1.0
feat: 同步immich最新代码，增加额外的clip模型
fix:  修改脚本中的调整向量长度逻辑，修复v0.9引入的返回结果类型不匹配问题



### PPP：
- 人脸模型效果未做测试，buffalo_l跟antelopev2都可
- mtphotos 默认CLIP向量长度为512，暂时未提供修改长度选项，所有需要执行脚本以修改向量长度（脚本未做大量测试，请自行判断可行性，后果自负）
- ~~未实现 OCR 功能，默认返回"",因为我用不到……~~ 增加使用mtphotos自带OCR
- OCR有已知内存泄漏问题，暂时无法解决；如果内存较少或长时间运行OCR导致内存溢出，请自行重启服务，或者设置MODEL_TTL参数，定时重启服务
- 只需人脸时，无需执行脚本，直接部署即可
- 不给openvino镜像传入IGPU相关参数时，会自动降级会CPU


### 效果自测，可联系
<img src="./1719887659169.jpg" width="150px"><img src="./mm_facetoface_collect_qrcode_1719888178476.png" width="150px"><img src="./mmqrcode1719888085154.png" width="150px">
