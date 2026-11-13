# cora_api.model.ViewReportModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**calc** | [**ViewReportCalcModel**](ViewReportCalcModel.md) | 계산. 집계 중에는 null이다. | 
**canConfirm** | **bool** | 내가 지금 \"자료 확인했어요\"를 누를 수 있으면 true(맡긴 쪽, 확인 전, 연결 계정 자료일 때만). | 
**canDispute** | **bool** | 내가 지금 이의를 제기할 수 있으면 true. | 
**canUploadEvidence** | **bool** | 내가 지금 캡처 자료를 올릴 수 있으면 true. | 
**confirmDueAt** | [**DateTime**](DateTime.md) | 확인 전일 때 자동으로 확인되는 시각. | 
**evidence** | [**ViewReportEvidenceModel**](ViewReportEvidenceModel.md) | 올라온 캡처 자료. 없으면 null. | 
**periodEnd** | [**DateTime**](DateTime.md) | 집계가 끝나는 시각. | 
**periodStart** | [**DateTime**](DateTime.md) | 집계 시작(링크 제출 시각). | 
**postUrl** | **String** | 크리에이터가 낸 게시 링크. | 
**source_** | [**ViewReportSource**](ViewReportSource.md) | CONNECTED_ACCOUNT: 연결한 인스타그램 계정에서 읽음, CAPTURE_PENDING: 캡처 자료(계산 전에 캡처가 제출된 상태, 또는 캡처로 만든 계산의 확인 전), CAPTURE_CONFIRMED: 캡처 자료(확정됨). | 
**status** | [**ViewReportStatus**](ViewReportStatus.md) | COUNTING: 집계 중(계산 없음), UNCONFIRMED: 계산이 나왔고 확인을 기다림, CONFIRMED: 확인되어 정산됨, DISPUTED: 이의가 걸려 돈이 그대로 보관됨. | 
**views** | **int** | 조회수. 집계 중에는 그날까지 읽은 값(없으면 null), 계산이 나온 뒤에는 정산에 쓰는 값. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


