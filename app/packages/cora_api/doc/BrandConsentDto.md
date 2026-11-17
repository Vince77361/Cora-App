# cora_api.model.BrandConsentDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accepted** | **List<String>** | 사용자가 확인한 세 줄. 서버가 만든 문구(myConsentTexts)와 정확히 같아야 한다. | [default to const []]
**method** | [**PaymentMethod**](PaymentMethod.md) |  | 
**termsVersion** | **int** | 동의하려는 판본 번호. 최신이 아니면 409 STALE_VERSION(latestVersion). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


