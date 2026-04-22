NAME      = ft_turing
SRCDIR    = src
BUILDDIR  = _build
SRCS      = $(SRCDIR)/types.ml $(SRCDIR)/ui.ml $(SRCDIR)/parser.ml $(SRCDIR)/main.ml
OCAMLFIND = ocamlfind
OCAMLOPT  = ocamlopt
PACKAGES  = yojson
FLAGS     = -package $(PACKAGES) -linkpkg -I $(BUILDDIR)

OBJS = $(patsubst $(SRCDIR)/%.ml, $(BUILDDIR)/%.cmx, $(SRCS))

all: $(BUILDDIR) $(NAME)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(NAME): $(OBJS)
	$(OCAMLFIND) $(OCAMLOPT) $(FLAGS) $(OBJS) -o $(NAME)
	dune build 2>/dev/null || true

$(BUILDDIR)/%.cmx: $(SRCDIR)/%.ml
	$(OCAMLFIND) $(OCAMLOPT) $(FLAGS) -c $< -o $@

clean:
	rm -rf $(BUILDDIR)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re
