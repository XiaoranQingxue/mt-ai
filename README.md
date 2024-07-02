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

### PPP：
- 人脸模型效果未做测试，buffalo_l跟antelopev2都可
- mtphotos 默认CLIP向量长度为512，暂时未提供修改长度选项，所有需要执行脚本以修改向量长度（脚本未做大量测试，请自行判断可行性，后果自负）
- 未实现 OCR 功能，默认返回"",因为我用不到……
- 只需人脸时，无需执行脚本，直接部署即可


### 效果自测，可联系
<img src="./1719887659169.jpg" width="150px"><img src="./mm_facetoface_collect_qrcode_1719888178476.png" width="150px"><img src="./mmqrcode1719888085154.png" width="150px">
