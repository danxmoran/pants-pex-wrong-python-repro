python_requirement(
    name="ssw",
    requirements=[
        "ssw-py@ git+https://github.com/mpcusack-color/ssw-py.git@b254233a1f48ffc160bff5d77a9b041c32e3cadf"
    ],
)

python_requirement(
    name="lib",
    requirements=["aldy==4.4", "setuptools"],
    dependencies=[":ssw"],
)

pex_binary(name="aldy", dependencies=[":lib"], entry_point="aldy")
