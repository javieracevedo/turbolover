module Db
  @fakeDB = {
      user: {
          name: "whoo",
          password: ""
      }
  }

  def fakeDB
    @fakeDB
  end
end
