# cora_api.model.MyStoreModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**bestShootingTime** | **String** |  | 
**category** | **String** |  | 
**coverPhotoUrl** | **String** |  | 
**customerPhrases** | **List<String>** | 손님들이 자주 한 말. | [default to const []]
**defaultTerms** | [**OfferTermsModel**](OfferTermsModel.md) |  | 
**hours** | **String** |  | 
**id** | **String** |  | 
**industry** | [**IndustryCategory**](IndustryCategory.md) |  | 
**intro** | **String** |  | 
**name** | **String** |  | 
**neighborhood** | **String** |  | 
**onboardingStep** | [**StoreOnboardingStep**](StoreOnboardingStep.md) |  | 
**publicUrl** | **String** | 공개 주소(cora.page/l/{slug}). 주소 이름이 없으면 null. | 
**recruitLine** | **String** |  | 
**regionSido** | **String** |  | 
**regionSigungu** | **String** |  | 
**seats** | **String** |  | 
**signatureMenu** | **String** |  | 
**slug** | **String** | 공개 주소 이름. 이름이 처음 생길 때 만들고 바꾸지 않는다. | 
**sourceLinks** | [**List<StoreSourceLinkModel>**](StoreSourceLinkModel.md) |  | [default to const []]
**status** | [**StoreStatus**](StoreStatus.md) |  | 
**tags** | **List<String>** | 꼬리표(# 없이). | [default to const []]
**trialBanner** | [**TrialBanner**](TrialBanner.md) | COMPARE: 종료일이 30일 안이라 비교를 보여 준다. HINT: 계약 정보를 넣으면 비교해 준다는 안내를 한 번 보여 준다. | 
**trialInfo** | [**TrialInfoModel**](TrialInfoModel.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


