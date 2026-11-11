# cora_api.model.CollaborationStepModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**at** | [**DateTime**](DateTime.md) | 그 단계가 끝난 시각. 기록이 없는 단계(방문·촬영)와 끝나지 않은 단계는 null. | 
**key** | [**CollaborationStepKey**](CollaborationStepKey.md) | 오퍼 수락, 가게 결제, 방문·촬영, 링크 제출, 조회수 집계 후 지급. 항상 이 다섯 개가 이 순서로 온다. | 
**state** | [**CollaborationStepState**](CollaborationStepState.md) | DONE: 끝남, NOW: 지금 하는 단계, TODO: 아직. 끝난 협업에는 NOW가 없다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


