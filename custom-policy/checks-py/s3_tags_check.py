from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class S3RequiredTagsCheck(BaseResourceCheck):
    """
    Memastikan setiap S3 bucket memiliki tag 'owner' dan 'environment'.
    """

    def __init__(self):
        name = "Pastikan S3 bucket memiliki tag owner dan environment"
        id = "CKV_CUSTOM_S3_1"
        supported_resources = ["aws_s3_bucket"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(
            name=name,
            id=id,
            categories=categories,
            supported_resources=supported_resources,
        )

    def scan_resource_conf(self, conf):
        tags = conf.get("tags", [{}])
        if isinstance(tags, list):
            tags = tags[0] if tags else {}
        required_tags = {"owner", "environment"}
        if isinstance(tags, dict) and required_tags.issubset(set(tags.keys())):
            return CheckResult.PASSED
        return CheckResult.FAILED


check = S3RequiredTagsCheck()
