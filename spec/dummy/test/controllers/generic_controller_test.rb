require "test_helper"

class GenericControllerTest < ActionDispatch::IntegrationTest
  test "Submit64 GetMetadata" do
    url = "/api/get-metadata-and-data-submit64"
    article1 = articles(:one)

    # Regular
    payload = {
      submit64Params: {
        resourceName: "Article",
        resourceId: article1.id
      }
    }
    post(url, params: payload)
    assert_response :success

  end

  test "Submit64 GetAssociationData" do
    url = "/api/get-association-data-submit64"
    article1 = articles(:one)

    # Regular
    payload = {
      submit64Params: {
        resourceName: "Article",
        resourceId: article1.id,
        associationName: "user",
        labelFilter: "",
        limit: 50,
        offset: 50
      }
    }
    post(url, params: payload)
    assert_response :success

  end

  test "Submit64 GetSubmitData" do
    url = "/api/get-submit-data-submit64"
    article1 = articles(:one)
    user1 = users(:one)

    # Regular
    payload = {
      submit64Params: {
        resourceName: "Article",
        resourceId: article1.id,
        resourceData: {
          a_string: "a new string",
          a_text: "a new text",
          a_number: 2000,
          a_float: 9.18,
          user: user1.id
        }
      }
    }
    post(url, params: payload)
    assert_response :success
  end

end
