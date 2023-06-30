variable aws_access {
    type = string
    default="AKIAU5C4MWT4VYDTNA3F"
    sensitive = true
}
variable aws_secret {
    type = string
    default="dJXQcP/eABKbcYWNv0ttQqrYUd6CZ3OgYVN3EOC0"
    sensitive = true
}

#constants
variable data_location {
    type = string
    default = "https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/master/pokedex.json"
}

variable bucket_name {
    type = string
    default = "pipeline-bucket23.3451dw"
}

variable pipeline_input {
    type = string
    default = "data-upload.json"
}

variable pipeline_output {
    type = string
    default = "data-output.json"
}

variable data_path {
    type = string
    default = "resources/source_data.json"
}
variable script_path {
    type = string
    default = "resources/glue_job.py"
}