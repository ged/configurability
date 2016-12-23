# -*- ruby -*-
#encoding: utf-8

require 'configurability'

class User
    extend Configurability

    configurability( :users ) do
        setting :min_password_length, default: 6
    end
end


