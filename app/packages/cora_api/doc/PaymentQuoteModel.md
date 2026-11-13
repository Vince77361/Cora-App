# cora_api.model.PaymentQuoteModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**creatorName** | **String** | 오퍼를 수락한 크리에이터의 활동 이름. | 
**creatorPhotoUrl** | **String** |  | 
**escrow** | **int** | 에스크로에 보관할 금액. 최대 현금 부담(고정 현금 + 조회수 수당 상한)이다. | 
**fee** | **int** | 서비스 수수료. 최대 현금 부담 × 수수료율을 내림한 값. | 
**feeRate** | **int** | 수수료율(%). | 
**fixedCash** | **int** | 고정 현금(원). 없으면 0. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**orderName** | **String** | PG에 넘기는 주문 이름. | 
**perViewCap** | **int** | 조회수 수당 상한(원). 조회수 수당이 없으면 null. | 
**pieces** | **int** | 콘텐츠 편 수. 오퍼는 지금 한 편이다. | 
**total** | **int** | 지금 결제할 금액(최대 현금 부담 + 수수료). | 
**voucherName** | **String** | 식사권 이름. 보상에 식사권이 없으면 null. | 
**voucherPeople** | **int** | 식사권 인원. 보상에 식사권이 없거나 모르면 null. | 
**voucherValue** | **int** | 식사권 금액(원). 보상에 식사권이 없으면 null. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


